# Engineering

Is the data built right?

The Engineering pillar evaluates transformation correctness, idempotency, performance, and pipeline reliability.
It focuses on the code that moves and transforms data — whether it produces correct results, handles failures gracefully, and can be re-run without producing duplicates or gaps.
When this pillar is weak, pipelines silently corrupt data, fail unrecoverably, or produce different results on each run.

**Critical principle — fail-safe defaults:** Silent data loss is a critical finding.
Unexpected input should fail visibly, not silently drop or coerce records.
A pipeline that crashes loudly is better than one that silently produces wrong results.

## Focus Areas

The Engineering pillar applies the duality through its primary lens.

### Decay Pattern focus (how the data is going wrong)

- **Silent corruption** — Engineering bugs produce silent corruption at the logic level.
  This is the most dangerous decay pattern because the pipeline "runs successfully" while producing wrong data.
  Look for: wrong join semantics, NULL handling that silently excludes rows, non-deterministic functions in business logic, missing aggregation guards on fan-out joins.

### Quality Dimension focus (what should protect against failure)

- **Validity** — Engineering validates data at ingestion and transformation — type checks, constraint enforcement, range validation.
  Invalid data should fail visibly, not be silently coerced.
- **Uniqueness** — Engineering implements idempotency (MERGE, DELETE-INSERT, UPSERT) that prevents duplicates on re-runs.
- **Accuracy** — Engineering ensures transformation logic produces correct results — the right aggregations, correct join semantics, proper NULL handling.

## Anti-Pattern Catalogue

### EP-01: Fan-out join without aggregation guard

`SUM(orders.amount)` after joining orders to line_items, inflating the sum by the number of line items per order.

**Why it matters:** Metrics are systematically wrong.
The query runs without error and produces plausible-looking numbers.
Decay Pattern: Silent corruption (Accuracy).
Typical severity: HIGH / L1.
Escalates to HYG if the metric feeds financial reporting.

### EP-02: Silent type coercion

`pd.to_numeric(df['amount'], errors='coerce')` — invalid values silently converted to NaN with no logging.

**Why it matters:** Invalid data is destroyed without a trace.
Downstream aggregations are understated.
Nobody knows records were lost.
Decay Pattern: Silent corruption (Accuracy).
Typical severity: HIGH / HYG (Irreversible — original values lost, aggregates wrong, no recovery path).

### EP-03: Non-deterministic transformation

`datetime.now()`, `random.random()`, or `uuid4()` used in business logic (not just metadata timestamps).

**Why it matters:** Re-running the pipeline produces different results.
Idempotency is broken.
Debugging is impossible because you can't reproduce the original output.
Decay Pattern: Silent corruption on re-runs (Uniqueness).
Typical severity: MEDIUM / L1.

### EP-04: NULL handling in JOIN conditions

`WHERE region = @region` where `@region` can be NULL, silently matching zero rows because `NULL = NULL` is false in SQL.

**Why it matters:** The query silently returns an empty result set or a subset of expected data.
No exception, no warning.
Decay Pattern: Silent corruption (Completeness).
Typical severity: HIGH / L1.

### EP-05: Full table scan when partition available

`SELECT * FROM events WHERE event_date = '2024-01-15'` without including the partition column in the predicate.

**Why it matters:** Scans the entire table instead of a single partition.
Cost scales with table size, not query selectivity.
In a shared warehouse, this can consume compute budget affecting other users.
Typical severity: MEDIUM / L1.
Escalates to HYG if it exhausts shared compute (Total test).

### EP-06: Missing idempotency on writes

Bare `INSERT INTO` without any deduplication mechanism (no MERGE, no DELETE-INSERT, no ON CONFLICT).

**Why it matters:** Pipeline re-run after failure creates duplicates.
Duplicate records inflate counts, sums, and other aggregates.
Decay Pattern: Silent corruption (Uniqueness).
Typical severity: HIGH / L1.

### EP-07: No error handling for external enrichment

`result = requests.get(api_url).json()` — no try/except, no timeout, no retry, no fallback.

**Why it matters:** API failure crashes the entire pipeline.
If partial results are written before the crash, consumers see a mix of enriched and un-enriched data.
Decay Pattern: Silent corruption if partial write occurs (Validity).
Typical severity: MEDIUM / L1.
Escalates to HYG if partial results are written without any indicator.

### EP-08: Cartesian join (missing join condition)

`FROM table_a, table_b` or `CROSS JOIN` without an intentional business reason.

**Why it matters:** Produces rows = table_a rows × table_b rows.
For tables with millions of rows, this exhausts memory, compute, and storage.
Decay Pattern: Silent corruption (Accuracy — meaningless output).
Typical severity: HIGH / L1.
Escalates to HYG if it exhausts shared resources (Total test).

### EP-09: Implicit type coercion in predicates

`WHERE user_id = '123'` when `user_id` is an INTEGER column.

**Why it matters:** Forces type coercion per row, preventing index use.
Some databases may produce unexpected results if the coercion is ambiguous.
Decay Pattern: Performance concern (Validity — type mismatch).
Typical severity: LOW / L1.

## Review Checklist

When assessing the Engineering pillar, work through each item in order.

1. **Idempotency** — Can the pipeline be re-run after failure without producing duplicates or gaps?
   What is the write strategy? Is it MERGE/UPSERT, DELETE-INSERT by partition, or bare INSERT?
   Are non-deterministic functions (`NOW()`, `RANDOM()`, `UUID()`) used in business logic?

2. **Join correctness** — Do any joins produce fan-out (1-to-many)?
   If so, is there an aggregation guard before metrics are calculated on the inflated rows?
   Are NULL values in join keys handled explicitly?
   Are there any unintentional cartesian products?

3. **Fail-safe validation** — When input data fails validation, what happens?
   Are invalid records logged, routed to a dead-letter queue, or silently coerced?
   Is type coercion used with `errors='coerce'` or `errors='ignore'` without logging?

4. **Error handling** — What happens when external dependencies (APIs, upstream tables) fail?
   Does the pipeline fail noisily or silently?
   Can processing resume without data loss or duplication after partial failure?

5. **Performance and cost** — Are partition columns used in predicates to avoid full table scans?
   Are there any queries that could exhaust shared warehouse resources?
   Are external API calls protected with timeouts and retry limits?

6. **Transformation correctness** — Are aggregation functions applied at the correct grain?
   Are business logic conditions (filters, status codes, date ranges) correct and documented?

## Severity Framing

Severity for Engineering findings is about the **data consequence** — what happens to consumer data if the code ships as-is.

- **Silent corruption** — Is the data wrong in a way that consumers will trust?
  Wrong aggregations in financial data are HYG.
  Wrong aggregations in internal dashboards are HIGH.
- **Fail-safe principle** — Does unexpected input fail visibly or silently?
  Silent drops and silent coercions that destroy data are HYG (Irreversible).
  Visible failures with error messages are MEDIUM.
- **Idempotency** — Does re-running produce duplicates?
  Duplicate financial records are HYG.
  Duplicate internal operational records are HIGH / L1.
