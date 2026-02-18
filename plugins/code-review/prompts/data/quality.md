# Quality

Does the data meet expectations?

The Quality pillar evaluates whether the data delivered to consumers meets their expectations for freshness, correctness, completeness, and understandability.
It focuses on what consumers experience — not what the pipeline produces.
When this pillar is weak, consumers discover quality issues by noticing wrong results rather than through monitoring, and tribal knowledge gates data access.

**Consumer-first perspective:** Always evaluate from the downstream consumer's perspective.
The question is not "did the pipeline run successfully?" but "can consumers trust and use this data?"

## Focus Areas

The Quality pillar applies the duality through two specific lenses.

### Decay Pattern focus (how the data is going wrong)

- **Freshness degradation** — Quality owns timeliness.
  If data is late, stale, or missing, consumers make decisions on outdated information.
  Look for: no `loaded_at` timestamps, no freshness SLOs, no alerting on processing delays, batch processing when consumers need near-real-time data.
- **Ownership erosion** — Quality owns usability.
  If data is undocumented, undiscoverable, or full of tribal knowledge, it fails the consumer regardless of correctness.
  Look for: undocumented magic numbers, no schema descriptions, business rules locked in the author's head.

### Quality Dimension focus (what should protect against failure)

- **Timeliness** — Freshness SLOs, processing latency, appropriate update frequency.
- **Completeness** — Expected row counts, required fields not NULL, no missing loads.
- **Accuracy** — Reconciliation between source and target.
  Bitemporality for audit-critical data.

## Anti-Pattern Catalogue

### QP-01: No freshness tracking

A table with no `loaded_at` timestamp, no watermark column, and no way to tell when the data was last updated.

**Why it matters:** Consumers cannot tell if data is current or stale.
If the pipeline fails silently, yesterday's data is served as today's.
No monitoring can be built because there's nothing to measure.
Decay Pattern: Freshness degradation (Timeliness).
Typical severity: MEDIUM / L2.
Escalates to HYG if the data feeds real-time operational decisions.

### QP-02: No uniqueness constraint on business key

Business key (order_number, customer_id + date) without a UNIQUE constraint, relying on the surrogate key for uniqueness.

**Why it matters:** Duplicate business records accumulate silently.
Aggregations are inflated.
The duplicates may not be discovered until a downstream report is questioned.
Decay Pattern: Silent corruption (Uniqueness).
Typical severity: HIGH / L1.
Escalates to HYG if the table feeds billing or financial reporting.

### QP-03: Undocumented magic numbers

`df[df['status'].isin([1, 3, 7])]` — filtering by numeric codes with no documentation of what the codes mean.

**Why it matters:** New team members can't maintain the code.
If the source system adds a new status code, this filter silently excludes it.
The business logic is locked in the author's head.
Decay Pattern: Ownership erosion (Completeness).
Typical severity: MEDIUM / L1.
Escalates to HIGH if the filtered-out statuses represent active records that consumers need.

### QP-04: No volume monitoring

A pipeline that loads data with no check on whether the load delivered a reasonable number of rows.

**Why it matters:** An empty load or a tiny load is accepted without question.
Consumers see a gap in data but no alert fires.
Decay Pattern: Freshness degradation (Completeness — expected records missing).
Typical severity: MEDIUM / L2.

### QP-05: No schema change detection

Pipeline ingests data from an external source with no check on whether the source schema has changed.

**Why it matters:** Source adds a column — no impact.
Source renames a column — pipeline either crashes or silently drops the column's data.
Source changes a type — implicit coercion may produce wrong results.
Decay Pattern: Schema drift (Consistency — source and target can diverge undetected).
Typical severity: MEDIUM / L2.

### QP-06: Over-engineered update frequency

Real-time streaming pipeline for data that consumers only check daily.

**Why it matters:** Costs more to run.
More complex to maintain.
More failure modes.
The extra timeliness provides no business value.
Decay Pattern: Engineering trade-off (Timeliness over-specified).
Typical severity: LOW / L2.

## Review Checklist

When assessing the Quality pillar, work through each item in order.

1. **Freshness expectations** — Is there a defined freshness SLO (documented or in configuration)?
   Is there a `loaded_at` timestamp, watermark, or other mechanism to measure processing latency?
   Is there monitoring or alerting that detects when data is stale before consumers do?

2. **Volume monitoring** — Is there a check on whether the expected number of rows arrived?
   Does the pipeline detect and alert on empty loads or anomalously small/large loads?
   What happens if the source system delivers 0 rows?

3. **Uniqueness** — Are business keys constrained to prevent duplicate records?
   Is there a UNIQUE constraint on the business key, not just the surrogate key?
   Is there deduplication in the pipeline if the constraint can't be enforced at the database level?

4. **Documentation and discoverability** — Can a new team member understand this data without asking someone?
   Are business rules (status codes, category values, magic numbers) documented alongside the code?
   Are schema descriptions present with consumer-facing language?

5. **Schema change detection** — If the source schema changes, will the pipeline detect it?
   Is there a schema validation step at the ingestion boundary?
   What happens if the source adds, renames, or removes a column?

6. **Update frequency appropriateness** — Does the update frequency match what consumers actually need?
   Is the pipeline more complex and costly than the business value of the timeliness requires?

## Severity Framing

Severity for Quality findings is about the **consumer experience** — what do consumers lose if the code ships as-is.

- **Freshness findings** — Is there a way to detect stale data before consumers do?
  No `loaded_at` timestamp at all is MEDIUM / L2.
  `loaded_at` exists but no monitoring is LOW / L2.
  Real-time operational data with no freshness tracking is HIGH / HYG.
- **Uniqueness findings** — Will duplicates inflate financial or operational metrics?
  Missing business key uniqueness on financial data is HIGH / L1.
  Missing uniqueness on internal operational data is HIGH / L1.
  Downstream deduplication exists as a mitigation: MEDIUM / L1.
- **Documentation findings** — Is the data usable by a new team member?
  Magic numbers that make filters unmaintainable are MEDIUM / L1.
  No schema descriptions on any fields is MEDIUM / L1.
  Some descriptions exist but incomplete is LOW / L1.
