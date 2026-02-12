# Calibration Examples -- Data Domain

> Worked examples showing how to judge severity and maturity level for real code patterns. Use these to calibrate prompt output and verify consistency across reviews.

## How to use this document

Each example follows the same four-part structure used across all domain calibration documents:
1. **Code pattern** -- what the reviewer sees
2. **Assessment** -- severity, maturity level, decay pattern/quality dimension
3. **Reasoning** -- why this severity and level, not higher or lower
4. **Boundary note** -- what would change the assessment up or down

---

## Architecture Pillar

### Example A1: Cross-domain table coupling (HIGH / L1)

**Code pattern:**
```sql
SELECT o.*, c.*, p.*, i.*
FROM sales.orders o
JOIN customer_service.customers c ON o.customer_id = c.id
JOIN marketing.products p ON o.product_id = p.id
JOIN warehouse.inventory i ON p.id = i.product_id;
```

**Assessment:** HIGH | L1 | Schema drift (Consistency)

**Reasoning:** This query reaches into three other domain's internal schemas. If any domain renames a column, changes a type, or restructures their tables, this query breaks. The coupling creates a maintenance burden that grows with every change in any of the four domains. This is an L1 gap (domain boundaries are not respected) and HIGH because the blast radius spans four domains.

**Boundary -- would be HYG if:** The query writes results to a widely-consumed dimension table. A breakage would cascade to all downstream consumers (Total test: yes).

**Boundary -- would be MEDIUM / L1 if:**
```sql
SELECT o.order_id, o.amount, c.customer_name
FROM sales.orders o
JOIN customer_service.customer_directory c ON o.customer_global_id = c.global_id;
```
The join uses a published interface (`customer_directory`) with a global identifier. Still cross-domain but via a contract, not internal tables. The concern shifts to whether the contract is formally defined.

### Example A2: Breaking column rename (HIGH / HYG)

**Code pattern:**
```sql
ALTER TABLE users RENAME COLUMN user_name TO username;
```

**Assessment:** HIGH | HYG | Schema drift (Irreversible test: yes)

**Reasoning:** All downstream consumers that reference `user_name` break immediately. If this is a published table with multiple consumers, the breakage is instant and affects all of them simultaneously. The rename is irreversible once deployed -- consumers cannot be "un-broken" without a rollback, and any data written between deploy and rollback may reference the new name while historical queries reference the old name.

**Boundary -- would be MEDIUM / L1 if:**
```sql
-- Phase 1: Add new column, backfill
ALTER TABLE users ADD COLUMN username VARCHAR(255);
UPDATE users SET username = user_name;
-- Phase 2 (next deploy, after consumers migrate): Drop old column
```
Two-phase migration with a deprecation period. Consumers have time to migrate. Phase 1 is reversible.

### Example A3: Deadly diamond (HIGH / L1)

**Code pattern:**
```sql
-- Two paths to the same target:
-- Path A: raw.orders -> enrichment.order_details -> analytics.daily_revenue (fast)
-- Path B: raw.orders -> fraud.scored_orders -> analytics.daily_revenue (slow)

INSERT INTO analytics.daily_revenue
SELECT d.order_id, d.amount, f.fraud_score
FROM enrichment.order_details d
JOIN fraud.scored_orders f ON d.order_id = f.order_id
WHERE d.order_date = CURRENT_DATE;
```

**Assessment:** HIGH | L1 | Silent corruption (Accuracy)

**Reasoning:** Path A completes in minutes, Path B takes hours. The target reads today's enriched orders but yesterday's fraud scores. Revenue totals are correct but fraud flags are stale -- or if both paths produce amount data, the join may inflate totals. This is silent corruption because the query runs without error and produces a result that looks plausible but is wrong.

**Boundary -- would be HYG if:** The daily_revenue table feeds a financial report or regulatory filing (Regulated test: yes, if financial reporting is involved).

**Boundary -- would be MEDIUM / L2 if:** Both paths are managed by a scheduler that gates the target on completion of both upstream tasks for the same partition. The risk then shifts to whether the dependency is correctly configured.

---

## Engineering Pillar

### Example E1: Silent type coercion (HIGH / HYG)

**Code pattern:**
```python
df['amount'] = pd.to_numeric(df['amount'], errors='coerce')
# Invalid values become NaN silently
df['total'] = df.groupby('category')['amount'].transform('sum')
```

**Assessment:** HIGH | HYG | Silent corruption (Irreversible test: yes)

**Reasoning:** Invalid amount values are silently converted to NaN. The subsequent `sum()` ignores NaN values, so the total is understated. This is silent -- no error, no log, no alert. The corrupted aggregates flow downstream to consumers who trust them. If those consumers make business decisions on understated totals, the damage is done before anyone detects it. Irreversible because the original invalid values are lost (coerced away) and the downstream decisions cannot be un-made.

**Boundary -- would be MEDIUM / L1 if:**
```python
invalid_mask = pd.to_numeric(df['amount'], errors='coerce').isna() & df['amount'].notna()
if invalid_mask.any():
    logger.warning(f"Invalid amounts found: {invalid_mask.sum()} records",
                   extra={"sample": df.loc[invalid_mask, 'amount'].head(5).tolist()})
    df_rejected = df[invalid_mask]
    # Route to dead-letter queue for investigation
df['amount'] = pd.to_numeric(df['amount'], errors='coerce')
```
The coercion still happens, but invalid records are logged and preserved. The data loss is detectable and recoverable.

### Example E2: Fan-out join inflating metrics (HIGH / L1)

**Code pattern:**
```sql
SELECT
    orders.order_id,
    SUM(orders.amount) AS total
FROM orders
JOIN line_items ON orders.order_id = line_items.order_id
GROUP BY orders.order_id;
```

**Assessment:** HIGH | L1 | Silent corruption (Accuracy)

**Reasoning:** Each order has multiple line items. The join produces one row per line item, so `SUM(orders.amount)` sums the order amount once per line item, inflating the total. If an order has 3 line items, the order amount is counted 3 times. This is a common SQL error that produces results that look reasonable (the query runs, numbers come out) but are systematically wrong.

**Boundary -- would be HYG if:** The inflated metric feeds a financial report or billing system (Irreversible -- invoices already sent, Regulated -- financial reporting).

**Boundary -- would be MEDIUM / L1 if:** The metric is for an internal dashboard with no downstream consumers. Still wrong but impact is contained.

### Example E3: Non-deterministic transformation (MEDIUM / L1)

**Code pattern:**
```python
df['processed_at'] = datetime.now()
df['random_sample'] = random.random()
```

**Assessment:** MEDIUM | L1 | Silent corruption (Uniqueness)

**Reasoning:** `datetime.now()` produces a different value on each run, so re-runs do not produce identical output. `random.random()` is non-reproducible. This breaks idempotency -- a pipeline re-run after failure produces different results, making it impossible to verify correctness or compare outputs. MEDIUM because the data isn't necessarily wrong (timestamps may be metadata), but the pipeline is not re-runnable.

**Boundary -- would be HIGH / L1 if:** `datetime.now()` is used in a business logic condition (e.g., `WHERE processed_at > cutoff`) that determines which records are included. Different runs produce different record sets.

**Boundary -- would be LOW / L1 if:** `processed_at` is a metadata column only, and the pipeline uses a separate deterministic business timestamp for all logic.

### Example E4: Missing error handling on external call (MEDIUM / L1)

**Code pattern:**
```python
result = requests.get(api_url).json()
df['enriched'] = result['data']
```

**Assessment:** MEDIUM | L1 | Silent corruption (Validity)

**Reasoning:** If the API fails, returns a non-JSON response, or returns JSON without a `data` key, this crashes the pipeline with an unhandled exception. The error message will be a Python traceback with no business context. MEDIUM because the failure is at least visible (crash, not silent), but there's no handling, no retry, no dead-letter queue, and the error message doesn't help operators diagnose the issue.

**Boundary -- would be HIGH / HYG if:** The API failure causes the pipeline to write a partial result (some records enriched, some not) without any indicator. Consumers get a mix of enriched and un-enriched data (Irreversible -- partial corruption).

---

## Quality Pillar

### Example Q1: No freshness tracking (MEDIUM / L2)

**Code pattern:**
```sql
CREATE TABLE daily_metrics (
    metric_date DATE,
    value DECIMAL
);
```

**Assessment:** MEDIUM | L2 | Freshness degradation (Timeliness)

**Reasoning:** There is no `loaded_at` timestamp, no `source_freshness` field, and no way to determine when this data was last updated. If the pipeline fails silently (data from yesterday is served as today's), consumers cannot tell from the data itself. This is an L2 gap because freshness monitoring requires something to measure against. MEDIUM because the data isn't wrong -- it's just impossible to verify currency.

**Boundary -- would be HIGH / HYG if:** The metrics feed a real-time dashboard used for incident response. Stale data could lead to wrong operational decisions (Irreversible -- incident response actions based on stale data).

**Boundary -- would be LOW / L2 if:** The table has a `loaded_at` column but no automated check compares it against an SLO. The mechanism exists but isn't monitored.

### Example Q2: No uniqueness constraint on business key (HIGH / L1)

**Code pattern:**
```sql
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    order_number VARCHAR(50),
    amount DECIMAL
);
```

**Assessment:** HIGH | L1 | Silent corruption (Uniqueness)

**Reasoning:** `order_number` is the business key but has no UNIQUE constraint. Duplicate orders will silently accumulate, inflating totals and counts. The surrogate `id` ensures row-level uniqueness but not business-level uniqueness. HIGH because duplicates in financial data produce systematically wrong aggregates.

**Boundary -- would be HYG if:** The orders table feeds a billing or invoicing system. Duplicate orders mean duplicate charges (Irreversible -- money already collected, Regulated -- financial accuracy).

**Boundary -- would be MEDIUM / L1 if:** The pipeline has a deduplication step downstream that handles duplicates. The constraint is still missing (defence in depth) but the practical impact is mitigated.

### Example Q3: Undocumented magic numbers (MEDIUM / L1)

**Code pattern:**
```python
df = df[df['status'].isin([1, 3, 7])]
```

**Assessment:** MEDIUM | L1 | Ownership erosion (Completeness)

**Reasoning:** What do status codes 1, 3, and 7 mean? Where is this documented? If the source system adds a new status code (8), this filter silently excludes it. A new team member cannot understand or maintain this logic without asking the author. MEDIUM because the logic may be correct today, but it's unmaintainable and will silently go wrong when the source system changes.

**Boundary -- would be HIGH / L1 if:** The filtered-out statuses represent active, important records. Silently excluding them causes data loss that consumers can't detect.

**Boundary -- would be LOW / L1 if:**
```python
ACTIVE_STATUSES = [1, 3, 7]  # Active, Approved, Complete (see docs/status-codes.md)
df = df[df['status'].isin(ACTIVE_STATUSES)]
```
Named constant with a documentation reference. The magic numbers are explained.

---

## Governance Pillar

### Example G1: PII in analytics layer (HIGH / HYG)

**Code pattern:**
```python
df_analytics = df[['user_id', 'email', 'phone', 'purchase_amount']]
df_analytics.to_parquet('s3://analytics-bucket/user_purchases/')
```

**Assessment:** HIGH | HYG | Compliance drift (Regulated test: yes)

**Reasoning:** Raw email and phone number are written to the analytics bucket without any masking, hashing, or pseudonymisation. The analytics bucket likely has broader access controls than the source system. This is a PII exposure that violates data protection principles (purpose limitation, data minimisation). Regulated: this violates GDPR/CCPA requirements for PII handling.

**Boundary -- would be MEDIUM / L2 if:**
```python
df_analytics = df[['user_id', 'purchase_amount']]
df_analytics['email_hash'] = df['email'].apply(lambda x: hashlib.sha256(x.encode()).hexdigest())
df_analytics.to_parquet('s3://analytics-bucket/user_purchases/')
```
PII is pseudonymised (hashed). Still has governance considerations (hash is reversible with a rainbow table if not salted) but the raw PII is not exposed.

### Example G2: PII in debug logging (HIGH / HYG)

**Code pattern:**
```sql
INSERT INTO debug_log (timestamp, context)
VALUES (NOW(), 'Processing user: email=john@example.com, ssn=123-45-6789');
```

**Assessment:** HIGH | HYG | Compliance drift (Regulated test: yes, Irreversible test: yes)

**Reasoning:** PII (email, SSN) is written to a debug log table. Debug logs typically have long retention, broad access, and are often aggregated into log management systems that cannot selectively delete records. The PII cannot be "unlogged" from these aggregated stores. This triggers both the Regulated test (PII exposure) and the Irreversible test (cannot undo the logging from aggregated stores).

**Boundary -- would be MEDIUM / L1 if:** The log entry contains only non-PII identifiers:
```sql
INSERT INTO debug_log (timestamp, context)
VALUES (NOW(), 'Processing user: user_id=12345, request_id=abc-def');
```
No PII, just operational identifiers. The logging pattern is fine.

### Example G3: No retention policy (MEDIUM / L2)

**Code pattern:**
```sql
CREATE TABLE user_events (
    event_id BIGINT,
    user_id INT,
    event_data JSON,
    created_at TIMESTAMP
);
```

**Assessment:** MEDIUM | L2 | Compliance drift (Completeness)

**Reasoning:** No partition scheme for lifecycle management, no TTL, no retention policy. The table grows forever. Storage costs increase linearly. If user_events contains PII, there's no mechanism for GDPR deletion or retention compliance. MEDIUM / L2 because the data isn't wrong today, but the lack of lifecycle management will become a compliance and cost problem over time.

**Boundary -- would be HIGH / HYG if:** The `event_data` JSON contains PII (health data, financial data) and the organisation is subject to GDPR/HIPAA. Unbounded retention of regulated data is a compliance violation (Regulated).

**Boundary -- would be LOW / L2 if:** The table is partitioned by `created_at` and there's a scheduled job that drops old partitions. The retention mechanism exists even if it's not documented as a formal policy.

### Example G4: Missing lineage (MEDIUM / L2)

**Code pattern:**
```sql
CREATE TABLE derived_metrics AS
SELECT customer_id, SUM(amount) AS total
FROM source_table
GROUP BY customer_id;
```

**Assessment:** MEDIUM | L2 | Ownership erosion (Accuracy)

**Reasoning:** `source_table` is an opaque reference -- which system does it come from? What transformations were applied upstream? If `derived_metrics` produces wrong numbers, there's no way to trace back to the root cause without reading code. Impact analysis is impossible -- if `source_table` changes, nobody knows that `derived_metrics` is affected. MEDIUM / L2 because the data may be correct today, but maintainability and debuggability are compromised.

**Boundary -- would be HIGH / L2 if:** The derived metrics feed external reports and the source table has multiple upstream contributors. Without lineage, a data quality issue in any upstream contributor is undiagnosable.

---

## Cross-pillar: How the same issue gets different assessments

### Missing data contract -- assessed by different pillars

A table consumed by multiple downstream teams with no formal contract:

| Pillar | Decay Pattern | Emphasis |
|--------|---------------|----------|
| **Architecture** | Schema drift | "No versioning strategy -- a column rename will break all consumers" |
| **Quality** | Ownership erosion | "Consumers have no documented expectations for freshness or completeness" |
| **Governance** | Compliance drift | "No data classification on the contract -- consumers don't know if they're handling PII" |

**During synthesis:** These merge into one finding if they reference the same table. The Architecture assessment sets the severity (HIGH if breaking changes are likely). The recommendation combines: "Define a data contract specifying schema stability (Architecture), quality expectations (Quality), and data classification (Governance)."
