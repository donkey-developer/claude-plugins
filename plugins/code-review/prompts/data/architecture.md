## Architecture Pillar — Is the Data Designed Right?

The Architecture pillar examines schema design, domain boundaries, and data contracts.
It evaluates whether data structures are appropriate for their access patterns, whether models respect bounded context boundaries, and whether published interfaces have formal agreements.
The primary lens is the downstream consumer: will they break, misinterpret, or lose trust if this ships?

## Focus Areas

- **Schema design** — structure is appropriate for the access pattern.
  Flag schemas optimised for writes when the dominant access is analytical reads, or denormalised structures serving frequent transactional updates.
- **Domain boundaries** — models respect bounded context boundaries.
  Flag queries that reach directly into another domain's internal tables rather than consuming from a published interface.
- **Contract completeness** — published interfaces have formal agreements.
  Flag tables consumed by multiple teams with no documented schema stability, versioning, or change management process.
- **Data product boundaries** — shared concepts use global identifiers.
  Flag cross-domain references using only local IDs with no global identifier for interoperability.
- **Naming consistency** — naming conventions are uniform within and across related tables.
  Flag mixed casing styles, inconsistent abbreviations, or conflicting column names for the same concept.
- **Migration safety** — schema changes follow multi-phase strategies.
  Flag column renames or drops with no backward-compatible migration plan, risking consumer breakage.
- **DAG integrity** — the data flow graph has no convergence paths that cause inconsistency.
  Flag pipelines where the same source reaches a target via multiple independent paths with different processing times.

## Anti-Patterns

### AP-01: Cross-domain table coupling

SQL query JOINs directly to another domain's internal tables rather than consuming from a published interface.
Consumer and producer become invisibly coupled; internal schema changes break unknown downstream queries.

```sql
-- Coupled: reading directly from another domain's internal table
SELECT o.id, c.credit_score
FROM orders o
JOIN credit_domain.internal_scores c ON o.customer_id = c.customer_id;
```

**Decay Pattern:** Schema drift | **Quality Dimension:** Consistency | **Severity:** HIGH / L1

### AP-02: Deadly diamond

A DAG where the same source data reaches a target via two or more independent paths with different processing times.
Metrics become inconsistent depending on which path completed first; reconciliation is impossible without reprocessing.

**Decay Pattern:** Silent corruption | **Quality Dimension:** Accuracy | **Severity:** HIGH / L1

### AP-03: Breaking column rename

`ALTER TABLE ... RENAME COLUMN` or `DROP COLUMN` without a multi-phase migration strategy.
All downstream consumers break simultaneously at deploy time.

```sql
-- Breaking: immediate rename with no transition period
ALTER TABLE orders RENAME COLUMN cust_id TO customer_id;

-- Safer: add new column, backfill, migrate consumers, then drop old column
ALTER TABLE orders ADD COLUMN customer_id INT;
```

**Decay Pattern:** Schema drift | **Quality Dimension:** Consistency | **Severity:** HIGH / HYG

### AP-04: Inconsistent naming conventions

Mixed casing styles in the same table or across related tables.
Consumers must guess or discover naming rules through trial and error.

```sql
-- Mixed conventions in the same schema
CREATE TABLE order_items (
    OrderId INT,          -- PascalCase
    product_name TEXT,    -- snake_case
    itemQty INT           -- camelCase
);
```

**Decay Pattern:** Schema drift | **Quality Dimension:** Consistency | **Severity:** MEDIUM / L1

### AP-05: Missing global identifier for polyseme

A table that references a cross-domain concept (e.g., "Customer", "Product") using only a local ID with no global identifier.
Cross-domain joins and reconciliation become impossible or unreliable.

**Decay Pattern:** Schema drift | **Quality Dimension:** Consistency | **Severity:** MEDIUM / L1

### AP-06: Schema inappropriate for use case

A highly normalised schema serving analytical queries requiring many joins, or a denormalised schema serving frequent transactional updates with consistency requirements.
Performance degrades and data quality erodes as the structure fights the access pattern.

**Decay Pattern:** Silent corruption | **Quality Dimension:** Validity | **Severity:** MEDIUM / L1

### AP-07: No data contract for published interface

A table consumed by multiple teams with no documented schema stability or change management process.
Breaking changes are discovered at runtime; consumers have no way to plan for or protect against upstream changes.

**Decay Pattern:** Schema drift + Ownership erosion | **Quality Dimension:** Consistency + Completeness | **Severity:** MEDIUM / L2

## Checklist

- [ ] Does the schema structure match the dominant access pattern (read-heavy, write-heavy, streaming)?
- [ ] Do data models respect bounded context boundaries, or do queries reach into other domains' internal tables?
- [ ] Are shared concepts mapped using global identifiers, not just local IDs?
- [ ] Will downstream consumers break if this schema change ships?
- [ ] Do published data products have formal contracts covering schema stability and change management?
- [ ] Are column renames or drops handled through multi-phase migration strategies?
- [ ] Does the DAG avoid deadly diamond patterns where the same source reaches a target via multiple paths?
- [ ] Are naming conventions consistent within and across related tables?
- [ ] Is the schema free from cross-domain table coupling (direct JOINs to another domain's internals)?
- [ ] Can the schema evolve without coordinated deployments across consuming teams?

## Positive Indicators

- Schema structure is intentionally matched to the dominant access pattern.
- Domain boundaries are clean: cross-domain data consumed only through published interfaces.
- Shared concepts carry global identifiers enabling reliable cross-domain joins.
- Published interfaces have formal data contracts with versioning and change management.
- Naming conventions are uniform and self-documenting across the schema.
