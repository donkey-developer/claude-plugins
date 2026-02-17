## Engineering Pillar — Is the Data Built Right?

The Engineering pillar examines transformation correctness, idempotency, performance, and pipeline reliability.
The core principle is fail-safe defaults: unexpected input must fail visibly, never silently drop or coerce data.

## Focus Areas

- **Transformation correctness** — aggregation logic, join semantics, and NULL handling produce accurate results.
  Flag fan-out joins followed by aggregation without guards, predicates that silently exclude NULL rows, and Cartesian products from missing join conditions.
- **Idempotency** — re-runs produce identical results and writes handle duplicates.
  Flag bare INSERT statements with no deduplication, and pipelines where partial failure leaves the target inconsistent.
- **Type safety** — type coercion is explicit and visible, not silent.
  Flag implicit conversions that discard invalid values without logging, and predicate type mismatches that prevent index usage.
- **Performance** — partition pruning, appropriate join strategies, and resource usage are proportionate to the query.
  Flag queries missing partition predicates on partitioned tables, and unbounded scans on large tables.
- **Error handling** — external calls have timeouts, retries, and fallbacks.
  Flag bare HTTP calls with no exception handling, and enrichment steps where failure silently produces partial results.
- **Pipeline reliability** — processing is deterministic and defaults are fail-safe.
  Flag use of `datetime.now()`, `random.random()`, or `uuid4()` in business logic, and any pattern where silent data loss is possible.

## Anti-Patterns

### EP-01: Fan-out join without aggregation guard

`SUM(orders.amount)` after joining orders to line_items inflates the sum by the number of line items per order.

```sql
SELECT o.customer_id, SUM(o.amount) AS total
FROM orders o JOIN line_items li ON o.id = li.order_id
GROUP BY o.customer_id;  -- amount inflated by fan-out
```

**Decay Pattern:** Silent corruption | **Quality Dimension:** Accuracy | **Severity:** HIGH / L1

### EP-02: Silent type coercion

`pd.to_numeric(df['amount'], errors='coerce')` silently converts invalid values to NaN with no logging.
Invalid data is destroyed without a trace and downstream aggregations are understated.

**Decay Pattern:** Silent corruption | **Quality Dimension:** Accuracy | **Severity:** HIGH / HYG (Irreversible)

### EP-03: Non-deterministic transformation

`datetime.now()`, `random.random()`, or `uuid4()` used in business logic rather than metadata timestamps.
Re-running the pipeline produces different results, breaking idempotency.

**Decay Pattern:** Silent corruption | **Quality Dimension:** Uniqueness | **Severity:** MEDIUM / L1

### EP-04: NULL handling in JOIN conditions

`WHERE region = @region` where `@region` can be NULL silently matches zero rows because `NULL = NULL` is false in SQL.

```sql
SELECT * FROM sales WHERE region = @region;  -- returns nothing when @region is NULL
SELECT * FROM sales WHERE region = @region OR (@region IS NULL AND region IS NULL);
```

**Decay Pattern:** Silent corruption | **Quality Dimension:** Completeness | **Severity:** HIGH / L1

### EP-05: Full table scan when partition available

Query without a partition predicate scans the entire partitioned table.
In shared warehouses this can exhaust compute budgets affecting other users.

**Decay Pattern:** Performance | **Quality Dimension:** Cost/performance | **Severity:** MEDIUM / L1

### EP-06: Implicit type coercion in predicates

`WHERE user_id = '123'` on an INTEGER column forces per-row coercion, preventing index usage.

**Decay Pattern:** Performance | **Quality Dimension:** Validity | **Severity:** LOW / L1

### EP-07: No error handling for external enrichment

`requests.get(api_url).json()` with no try/except, no timeout, and no fallback.

```python
result = requests.get(api_url).json()  # crashes pipeline on any failure
```

**Decay Pattern:** Silent corruption | **Quality Dimension:** Validity | **Severity:** MEDIUM / L1

### EP-08: Missing idempotency on writes

Bare `INSERT INTO` without deduplication (no MERGE, no DELETE-INSERT, no ON CONFLICT).
Re-run after failure creates duplicates that inflate counts and aggregates.

```sql
INSERT INTO target SELECT id, amount FROM staging;  -- duplicates on re-run
MERGE INTO target t USING staging s ON t.id = s.id   -- idempotent alternative
WHEN MATCHED THEN UPDATE SET amount = s.amount
WHEN NOT MATCHED THEN INSERT (id, amount) VALUES (s.id, s.amount);
```

**Decay Pattern:** Silent corruption | **Quality Dimension:** Uniqueness | **Severity:** HIGH / L1

### EP-09: Cartesian join (missing join condition)

`FROM table_a, table_b` or `CROSS JOIN` without an intentional business reason.
Produces rows equal to table_a multiplied by table_b, potentially exhausting memory and compute.

**Decay Pattern:** Silent corruption | **Quality Dimension:** Accuracy | **Severity:** HIGH / L1

## Checklist

- [ ] Do aggregations account for join fan-out, or are metrics inflated by one-to-many relationships?
- [ ] Are writes idempotent — will a pipeline re-run produce the same result without duplicates?
- [ ] Is type coercion explicit and logged, or does it silently discard invalid values?
- [ ] Are NULL values handled explicitly in JOIN and WHERE conditions?
- [ ] Do queries on partitioned tables include the partition predicate?
- [ ] Are external enrichment calls wrapped with timeouts, retries, and error handling?
- [ ] Is business logic free of non-deterministic functions (`NOW()`, `RANDOM()`, `UUID()`)?
- [ ] Do all join conditions have explicit predicates, with no accidental Cartesian products?
- [ ] Does unexpected or invalid input fail visibly rather than silently dropping data?
- [ ] Are predicate types consistent with column types, avoiding implicit coercion?

## Positive Indicators

- Aggregations use pre-aggregation or explicit fan-out guards before joining.
- Writes use MERGE, DELETE-INSERT, or ON CONFLICT for safe re-runs.
- Type validation is explicit with logging for rejected records.
- NULL handling is deliberate and documented in query logic.
- External dependencies have timeouts, retries, and fallback behaviour.
- Pipeline failures surface visibly through logging, alerting, or dead-letter queues.
- Partition pruning is used consistently on large tables.
