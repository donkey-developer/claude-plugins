## Quality Pillar — Does the Data Meet Expectations?

The Quality pillar examines freshness, completeness, accuracy, and documentation from the consumer's perspective.
It evaluates whether data arrives on time, whether it contains what consumers expect, and whether it can be understood without tribal knowledge.
The central question is: if this data is wrong, how would anyone know?

## Focus Areas

- **Freshness SLOs** — timeliness expectations are defined, documented, and monitored.
  Flag tables with no `loaded_at` or watermark column, and pipelines with no alerting when data arrives late.
- **Validation coverage** — automated quality checks guard every stage of the pipeline.
  Flag pipelines that accept data without checking row counts, null rates, or value distributions.
- **Documentation adequacy** — data is understandable without asking someone.
  Flag magic numbers, undocumented business rules, and columns with no descriptions.
- **Completeness** — expected row counts, required fields, and load expectations are enforced.
  Flag loads accepted with zero rows, required columns containing NULLs, and missing partition loads with no alert.
- **Accuracy** — source and target are reconcilable.
  Flag pipelines with no reconciliation step between source and target, and audit-critical data with no bitemporality.

## Anti-Patterns

### QP-01: No freshness tracking

A table with no `loaded_at` timestamp, no watermark column, and no way for consumers to tell when data was last updated.
Consumers make decisions on information of unknown age.

```sql
CREATE TABLE daily_revenue (
    region TEXT,
    revenue DECIMAL(18,2)
    -- no loaded_at, no watermark — consumers cannot assess freshness
);
```

**Decay Pattern:** Freshness degradation | **Quality Dimension:** Timeliness | **Severity:** MEDIUM / L2

### QP-02: No uniqueness constraint on business key

Business key without a UNIQUE constraint, relying solely on a surrogate key for uniqueness.
Duplicate business records accumulate silently, inflating totals and corrupting downstream aggregations.

```sql
CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    customer_code TEXT,  -- no UNIQUE constraint; duplicates accumulate silently
    name TEXT
);
```

**Decay Pattern:** Silent corruption | **Quality Dimension:** Uniqueness | **Severity:** HIGH / L1

### QP-03: Undocumented magic numbers

Filtering or branching on numeric codes with no documentation explaining what the values mean.
New team members cannot maintain the code, and new status codes are silently excluded from results.

```python
# What do 1, 3, and 7 mean? No one remembers.
df = df[df['status'].isin([1, 3, 7])]
```

**Decay Pattern:** Ownership erosion | **Quality Dimension:** Completeness | **Severity:** MEDIUM / L1

### QP-04: No volume monitoring

A pipeline that loads data with no check on row count reasonability.
Empty or partial loads are accepted without question; consumers discover missing data only when reports look wrong.

```python
df = extract_from_source()
df.to_sql('target_table', engine, if_exists='append')  # loads zero rows without complaint
```

**Decay Pattern:** Freshness degradation | **Quality Dimension:** Completeness | **Severity:** MEDIUM / L2

### QP-05: No schema change detection

Pipeline ingests from an external source with no validation that the schema matches expectations.
Column renames, type changes, or dropped columns cause silent data loss or wrong coercion.

```python
# Blindly trusts that the source schema hasn't changed
df = pd.read_csv(source_url)
df.to_sql('target', engine, if_exists='replace')
```

**Decay Pattern:** Schema drift | **Quality Dimension:** Consistency | **Severity:** MEDIUM / L2

### QP-06: Over-engineered update frequency

Real-time streaming pipeline for data that consumers only check daily or weekly.
Extra infrastructure and operational cost provide no business value when consumers do not need sub-day freshness.

**Decay Pattern:** N/A | **Quality Dimension:** Timeliness | **Severity:** LOW / L2

## Checklist

- [ ] If this data is wrong, how would we know?
- [ ] Is there a freshness SLO, and is it documented and monitored?
- [ ] Can a new team member understand this data without asking someone?
- [ ] What happens if source data arrives late — do consumers get stale data or an alert?
- [ ] Do business keys have uniqueness constraints, or can duplicates accumulate silently?
- [ ] Are magic numbers and business rule codes documented at the point of use?
- [ ] Does the pipeline validate row counts and reject empty or suspiciously small loads?
- [ ] Is there a schema validation step that detects upstream column changes before loading?
- [ ] Are source-to-target reconciliation checks in place for accuracy-critical data?
- [ ] Is the update frequency matched to actual consumer needs, not over- or under-engineered?

## Positive Indicators

- Every table has a freshness column (`loaded_at`, watermark, or equivalent) that consumers can query.
- Business keys carry uniqueness constraints enforced at the storage layer.
- Business rule codes are documented with named constants or lookup tables.
- Pipelines validate row counts and schema before writing to target tables.
- Freshness SLOs are documented, monitored, and alerted on.
- Source-to-target reconciliation runs automatically for accuracy-critical data.
- Documentation enables a new team member to understand the data without tribal knowledge.
