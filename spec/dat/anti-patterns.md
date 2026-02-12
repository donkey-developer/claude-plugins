# Anti-Patterns Catalogue -- Data Domain

> Complete catalogue of code patterns that Data reviewers should flag. Organised by pillar, with Decay Pattern / Quality Dimension classification and typical severity.

## How to use this document

Each anti-pattern includes:
- **Pattern name** -- a short, memorable label
- **What it looks like** -- concrete code description
- **Why it's bad** -- data impact on consumers
- **Decay Pattern / Quality Dimension** -- which failure mechanism and which missing quality property
- **Typical severity** -- default assessment (may be higher or lower depending on context)

When adding new anti-patterns to prompts, follow this structure. Use concrete descriptions, not abstract categories.

---

## Architecture Pillar Anti-Patterns

### AP-01: Cross-domain table coupling

**What it looks like:** SQL query that JOINs directly to another domain's internal tables rather than consuming from a published interface or data contract.

**Why it's bad:** Any schema change in the other domain breaks this query. The coupling is invisible to the other domain -- they don't know they have a consumer. Changes cascade unpredictably.

**Decay Pattern:** Schema drift
**Quality Dimension:** Consistency (cross-domain data accessed through unstable internal interfaces)
**Typical severity:** HIGH / L1

### AP-02: Deadly diamond

**What it looks like:** A DAG where the same source data reaches a target via two or more independent paths with different processing times.

**Why it's bad:** The target sees data from different points in time. Fast path has today's data, slow path has yesterday's. Joins between the paths produce wrong results. Metrics may be inflated if the same records arrive via both paths.

**Decay Pattern:** Silent corruption
**Quality Dimension:** Accuracy (data from different time windows joined as if contemporaneous)
**Typical severity:** HIGH / L1 (escalates to HYG if the target feeds financial or regulatory reporting)

### AP-03: Breaking column rename

**What it looks like:** `ALTER TABLE ... RENAME COLUMN` or `ALTER TABLE ... DROP COLUMN` without a multi-phase migration strategy.

**Why it's bad:** All downstream consumers break immediately. If the table is widely consumed, the breakage is total. The rename cannot be undone without a backup restore.

**Decay Pattern:** Schema drift
**Quality Dimension:** Consistency (contract with consumers broken)
**Typical severity:** HIGH / HYG (Irreversible -- data and schema permanently changed)

### AP-04: Inconsistent naming conventions

**What it looks like:** Mixed casing styles in the same table or across related tables: `user_id`, `firstName`, `LAST_NAME`, `EmailAddress`.

**Why it's bad:** Consumers cannot predict column names. Copy-paste queries fail on case-sensitive platforms. New team members waste time figuring out the naming pattern.

**Decay Pattern:** Schema drift (slow, insidious)
**Quality Dimension:** Consistency
**Typical severity:** MEDIUM / L1

### AP-05: Missing global identifier for polyseme

**What it looks like:** A table that references a cross-domain concept (customer, product, order) using only a local ID with no global identifier.

**Why it's bad:** Cross-domain joins are impossible or require a fragile mapping table. If the local ID scheme changes, all cross-domain references break.

**Decay Pattern:** Schema drift
**Quality Dimension:** Consistency (no interoperability mechanism)
**Typical severity:** MEDIUM / L1

### AP-06: Schema inappropriate for use case

**What it looks like:** A highly normalised (3NF) schema used for analytical queries, or a denormalised star schema used for transactional updates.

**Why it's bad:** Wrong schema design creates permanent performance problems. 3NF for analytics means expensive multi-table joins on every query. Star schema for OLTP means update anomalies and denormalisation drift.

**Decay Pattern:** Silent corruption (for star schema OLTP -- update anomalies)
**Quality Dimension:** Validity (data model doesn't match access pattern)
**Typical severity:** MEDIUM / L1

### AP-07: No data contract for published interface

**What it looks like:** A table consumed by multiple teams or systems with no documentation of schema stability, quality expectations, or change management process.

**Why it's bad:** Consumers have no way to know what's stable, what might change, or what quality to expect. The producer has no way to know who their consumers are. Breaking changes are discovered by breakage.

**Decay Pattern:** Schema drift + Ownership erosion
**Quality Dimension:** Consistency + Completeness
**Typical severity:** MEDIUM / L2

---

## Engineering Pillar Anti-Patterns

### EP-01: Fan-out join without aggregation guard

**What it looks like:** `SUM(orders.amount)` after joining orders to line_items, inflating the sum by the number of line items per order.

**Why it's bad:** Metrics are systematically wrong. The query runs without error and produces plausible-looking numbers. The inflation may not be obvious unless someone manually reconciles.

**Decay Pattern:** Silent corruption
**Quality Dimension:** Accuracy (aggregation logic is wrong)
**Typical severity:** HIGH / L1 (escalates to HYG if the metric feeds financial reporting)

### EP-02: Silent type coercion

**What it looks like:** `pd.to_numeric(df['amount'], errors='coerce')` -- invalid values silently converted to NaN with no logging.

**Why it's bad:** Invalid data is destroyed without a trace. Downstream aggregations are understated. Nobody knows records were lost.

**Decay Pattern:** Silent corruption
**Quality Dimension:** Accuracy (invalid data silently removed)
**Typical severity:** HIGH / HYG (Irreversible -- original values are lost and aggregates are wrong)

### EP-03: Non-deterministic transformation

**What it looks like:** `datetime.now()`, `random.random()`, or `uuid4()` used in business logic (not just metadata timestamps).

**Why it's bad:** Re-running the pipeline produces different results. Idempotency is broken. Debugging is impossible because you can't reproduce the original output.

**Decay Pattern:** Silent corruption (on re-runs)
**Quality Dimension:** Uniqueness (different outputs per run)
**Typical severity:** MEDIUM / L1

### EP-04: NULL handling in JOIN conditions

**What it looks like:** `WHERE region = @region` where `@region` can be NULL, silently matching zero rows because `NULL = NULL` is false in SQL.

**Why it's bad:** The query silently returns an empty result set or a subset of expected data. The error is invisible -- no exception, no warning.

**Decay Pattern:** Silent corruption
**Quality Dimension:** Completeness (records silently excluded)
**Typical severity:** HIGH / L1

### EP-05: Full table scan when partition available

**What it looks like:** `SELECT * FROM events WHERE event_date = '2024-01-15'` without including the partition column in the predicate.

**Why it's bad:** Scans the entire table instead of a single partition. Cost scales with table size, not query selectivity. In a shared warehouse, this can consume compute budget that affects other users.

**Decay Pattern:** (Performance, not a decay pattern)
**Quality Dimension:** (Cost/performance concern)
**Typical severity:** MEDIUM / L1 (escalates to HYG if it exhausts shared compute -- Total)

### EP-06: Implicit type coercion in predicates

**What it looks like:** `WHERE user_id = '123'` when `user_id` is an INTEGER column.

**Why it's bad:** The database must coerce the string to an integer for every row, preventing index use. Some databases may produce unexpected results if the coercion is ambiguous.

**Decay Pattern:** (Performance concern)
**Quality Dimension:** Validity (type mismatch)
**Typical severity:** LOW / L1

### EP-07: No error handling for external enrichment

**What it looks like:** `result = requests.get(api_url).json()` -- no try/except, no timeout, no retry, no fallback.

**Why it's bad:** API failure crashes the entire pipeline. No partial result handling. Error message is a Python traceback with no business context.

**Decay Pattern:** Silent corruption (if partial results are written before the crash)
**Quality Dimension:** Validity (no input validation on external data)
**Typical severity:** MEDIUM / L1

### EP-08: Missing idempotency on writes

**What it looks like:** Bare `INSERT INTO` without any deduplication mechanism (no MERGE, no DELETE-INSERT, no ON CONFLICT).

**Why it's bad:** Pipeline re-run after failure creates duplicates. Duplicate records inflate counts, sums, and other aggregates.

**Decay Pattern:** Silent corruption
**Quality Dimension:** Uniqueness (duplicates on re-run)
**Typical severity:** HIGH / L1

### EP-09: Cartesian join (missing join condition)

**What it looks like:** `FROM table_a, table_b` or `CROSS JOIN` without an intentional business reason.

**Why it's bad:** Produces rows = table_a rows x table_b rows. For tables with millions of rows, this can exhaust memory, compute, and storage. The result is meaningless.

**Decay Pattern:** Silent corruption (meaningless output that may pass row count checks)
**Quality Dimension:** Accuracy
**Typical severity:** HIGH / L1 (escalates to HYG if it exhausts shared resources -- Total)

---

## Quality Pillar Anti-Patterns

### QP-01: No freshness tracking

**What it looks like:** A table with no `loaded_at` timestamp, no watermark column, and no way to tell when the data was last updated.

**Why it's bad:** Consumers cannot tell if data is current or stale. If the pipeline fails silently, yesterday's data is served as today's. No monitoring can be built because there's nothing to measure.

**Decay Pattern:** Freshness degradation
**Quality Dimension:** Timeliness (currency is unmeasurable)
**Typical severity:** MEDIUM / L2

### QP-02: No uniqueness constraint on business key

**What it looks like:** Business key (order_number, customer_id + date) without a UNIQUE constraint, relying on the surrogate key (auto-increment id) for uniqueness.

**Why it's bad:** Duplicate business records accumulate silently. Aggregations are inflated. The duplicates may not be discovered until a downstream report is questioned.

**Decay Pattern:** Silent corruption
**Quality Dimension:** Uniqueness
**Typical severity:** HIGH / L1

### QP-03: Undocumented magic numbers

**What it looks like:** `df[df['status'].isin([1, 3, 7])]` -- filtering by numeric codes with no documentation of what the codes mean.

**Why it's bad:** New team members can't maintain the code. If the source system adds a new status code, this filter silently excludes it. The business logic is locked in the author's head.

**Decay Pattern:** Ownership erosion
**Quality Dimension:** Completeness (documentation missing)
**Typical severity:** MEDIUM / L1

### QP-04: No volume monitoring

**What it looks like:** A pipeline that loads data with no check on whether the load delivered a reasonable number of rows.

**Why it's bad:** An empty load (0 rows) or a tiny load (source system down, only partial data) is accepted without question. Consumers see a gap in data but no alert fires.

**Decay Pattern:** Freshness degradation (missing data appears as staleness)
**Quality Dimension:** Completeness (expected records missing)
**Typical severity:** MEDIUM / L2

### QP-05: No schema change detection

**What it looks like:** Pipeline ingests data from an external source with no check on whether the source schema has changed.

**Why it's bad:** Source adds a column -- no impact. Source renames a column -- pipeline either crashes (best case) or silently drops the column's data (worst case). Source changes a type -- implicit coercion may produce wrong results.

**Decay Pattern:** Schema drift
**Quality Dimension:** Consistency (source and target schema can diverge undetected)
**Typical severity:** MEDIUM / L2

### QP-06: Over-engineered update frequency

**What it looks like:** Real-time streaming pipeline for data that consumers only check daily.

**Why it's bad:** Costs more to run. More complex to maintain. More failure modes. The extra timeliness provides no business value.

**Decay Pattern:** (Not a decay pattern -- an engineering trade-off)
**Quality Dimension:** Timeliness (over-specification, not under-specification)
**Typical severity:** LOW / L2

---

## Governance Pillar Anti-Patterns

### GP-01: PII in analytics without masking

**What it looks like:** Raw email addresses, phone numbers, or SSNs written to analytics tables, data lakes, or exported files without hashing, tokenisation, or redaction.

**Why it's bad:** Analytics layers typically have broader access controls. PII is now accessible to anyone with analytics access. Violates data minimisation and purpose limitation principles. GDPR/CCPA compliance risk.

**Decay Pattern:** Compliance drift
**Quality Dimension:** (Regulated data concern)
**Typical severity:** HIGH / HYG (Regulated -- PII exposure)

### GP-02: PII in logs

**What it looks like:** PII (email, SSN, health data) interpolated into log messages, debug tables, or error output.

**Why it's bad:** Logs are aggregated, retained, and often have broad access. PII cannot be selectively removed from log aggregation systems. The PII persists in log history even if the code is fixed.

**Decay Pattern:** Compliance drift
**Quality Dimension:** (Regulated data concern)
**Typical severity:** HIGH / HYG (Regulated + Irreversible -- cannot unlog from aggregated stores)

### GP-03: No retention policy

**What it looks like:** Tables with no partition scheme for lifecycle management, no TTL, no scheduled purge job. Table grows forever.

**Why it's bad:** Storage costs grow linearly. If the table contains PII, there's no mechanism for GDPR deletion or retention compliance. Query performance degrades as the table grows.

**Decay Pattern:** Compliance drift
**Quality Dimension:** Completeness (lifecycle metadata missing)
**Typical severity:** MEDIUM / L2 (escalates to HYG if the table contains regulated data -- Regulated)

### GP-04: No ownership metadata

**What it looks like:** A table with no documented owner -- no comments, no catalog entry, no contact information.

**Why it's bad:** When something goes wrong, nobody knows who to call. When the data needs updating, nobody takes responsibility. The data becomes an orphan that deteriorates over time.

**Decay Pattern:** Ownership erosion
**Quality Dimension:** Completeness (owner metadata missing)
**Typical severity:** MEDIUM / L1

### GP-05: No lineage tracking

**What it looks like:** Derived tables that reference source tables with no documentation of the transformation chain. `CREATE TABLE derived AS SELECT ... FROM source` -- which source system? What upstream transformations?

**Why it's bad:** Impact analysis is impossible. Root cause analysis requires code archaeology. When the source changes, nobody knows what's affected.

**Decay Pattern:** Ownership erosion
**Quality Dimension:** Accuracy (lineage correctness unverifiable)
**Typical severity:** MEDIUM / L2

### GP-06: No Right-to-be-Forgotten mechanism

**What it looks like:** System processes EU citizen data but has no mechanism to identify and remove a specific user's data across all tables and downstream systems.

**Why it's bad:** GDPR Article 17 requires the ability to delete personal data on request. Without a mechanism, the organisation cannot comply, risking fines of up to 4% of global revenue.

**Decay Pattern:** Compliance drift
**Quality Dimension:** (Regulated data concern)
**Typical severity:** HIGH / HYG (Regulated -- GDPR non-compliance)

### GP-07: Missing data classification

**What it looks like:** A table containing sensitive data (customer records, financial transactions, health data) with no classification label indicating its sensitivity level.

**Why it's bad:** Without classification, access controls can't be calibrated. Teams don't know what controls to apply. Sensitive data may be copied to less-protected environments.

**Decay Pattern:** Compliance drift
**Quality Dimension:** Completeness (classification metadata missing)
**Typical severity:** MEDIUM / L1 (escalates to HIGH if the data is clearly PII or regulated)

### GP-08: Unmasked PII in non-production environments

**What it looks like:** Production data copied to development or staging environments without masking PII.

**Why it's bad:** Non-production environments typically have weaker access controls. Developers and testers gain access to real customer data. Violates data minimisation principles.

**Decay Pattern:** Compliance drift
**Quality Dimension:** (Regulated data concern)
**Typical severity:** HIGH / HYG (Regulated -- PII in uncontrolled environment)

---

## Adding New Anti-Patterns

When adding a new anti-pattern to this catalogue or to the prompts:

1. Give it a **short, memorable name** (not "Bad Practice #7")
2. Describe **what it looks like** in code (concrete SQL/Python/config, not abstract)
3. Explain **why it's bad** in terms of data impact on consumers
4. Classify with **Decay Pattern** and **Quality Dimension**
5. Assign a **typical severity** with reasoning
6. Note **boundary conditions** that would change the severity
