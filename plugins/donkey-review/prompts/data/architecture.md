# Architecture

Is the data designed right?

The Architecture pillar evaluates schema design, domain boundaries, data contracts, and structural properties that determine whether the data product will hold up as the system evolves.
When this pillar is weak, schema changes break consumers silently, cross-domain coupling makes independent evolution impossible, and data products lack the structural properties needed for their use case.

## Focus Areas

The Architecture pillar applies the duality through two specific lenses.

### Decay Pattern focus (how the data is going wrong)

- **Schema drift** — Architecture owns schema design decisions.
  A column rename, type change, or semantic change is an architectural choice that cascades to all consumers.
  Look for: breaking column renames, type changes without migration, naming inconsistencies, missing data contracts.
- **Silent corruption** — Deadly diamonds and cross-domain coupling are architectural flaws that produce silent corruption at the structural level.
  Look for: fan-out DAG paths to the same target, cross-domain direct table access, schemas inappropriate for their access pattern.

### Quality Dimension focus (what should protect against failure)

- **Consistency** — Schema design determines whether data is consistent across domains.
  Polysemes without global identifiers create systemic inconsistency.
  Published interfaces without contracts create invisible coupling.
- **Validity** — Schema constraints, type choices, and design decisions determine what data can exist.
  A schema appropriate for its use case enforces valid data by construction.

## Anti-Pattern Catalogue

### AP-01: Cross-domain table coupling

Direct JOIN to another domain's internal tables rather than consuming from a published interface.

**Why it matters:** Any schema change in the other domain breaks this query.
The coupling is invisible to the other domain — they don't know they have a consumer.
Decay Pattern: Schema drift (Consistency).
Typical severity: HIGH / L1.

### AP-02: Deadly diamond

A DAG where the same source data reaches a target via two or more independent paths with different processing times.

**Why it matters:** The target sees data from different points in time.
Fast path has today's data, slow path has yesterday's.
Joins between the paths produce wrong results.
Decay Pattern: Silent corruption (Accuracy).
Typical severity: HIGH / L1.
Escalates to HYG if the target feeds financial or regulatory reporting.

### AP-03: Breaking column rename or drop

`ALTER TABLE ... RENAME COLUMN` or `ALTER TABLE ... DROP COLUMN` without a multi-phase migration strategy.

**Why it matters:** All downstream consumers break immediately.
The rename cannot be undone without a backup restore.
Decay Pattern: Schema drift (Consistency).
Typical severity: HIGH / HYG (Irreversible — consumers broken, schema permanently changed).

### AP-04: Inconsistent naming conventions

Mixed casing styles in the same table or across related tables: `user_id`, `firstName`, `LAST_NAME`.

**Why it matters:** Consumers cannot predict column names.
Copy-paste queries fail on case-sensitive platforms.
Decay Pattern: Schema drift (Consistency).
Typical severity: MEDIUM / L1.

### AP-05: Missing global identifier for polyseme

A table that references a cross-domain concept (customer, product, order) using only a local ID with no global identifier.

**Why it matters:** Cross-domain joins are impossible or require a fragile mapping table.
Decay Pattern: Schema drift (Consistency).
Typical severity: MEDIUM / L1.

### AP-06: Schema inappropriate for use case

Schema design that does not match the intended access pattern — for example, a highly normalised schema serving analytical queries requiring expensive multi-table joins.

**Why it matters:** Wrong schema design creates permanent performance problems.
Describe the structural property the data should exhibit for its use case — do not prescribe specific modelling approaches.
Decay Pattern: Silent corruption via update anomalies (Validity).
Typical severity: MEDIUM / L1.

### AP-07: No data contract for published interface

A table consumed by multiple teams or systems with no documentation of schema stability, quality expectations, or change management process.

**Why it matters:** Consumers have no way to know what's stable, what might change, or what quality to expect.
Breaking changes are discovered by breakage.
Decay Pattern: Schema drift + Ownership erosion (Consistency + Completeness).
Typical severity: MEDIUM / L2.

## Review Checklist

When assessing the Architecture pillar, work through each item in order.

1. **Domain boundaries** — Does the code access other domains through published interfaces or by joining internal tables directly?
   Are shared concepts (customers, products, orders) identified with global identifiers or only domain-local IDs?

2. **Schema change safety** — Do any changes rename, retype, or remove columns?
   Is there a multi-phase migration strategy (add new → backfill → deprecate old → remove old)?
   Will downstream consumers break immediately if this is deployed?

3. **Structural properties** — Does the schema design exhibit the structural properties appropriate for its use case?
   Is the schema appropriate for the query patterns it will serve?
   Describe what the schema should look like — do not prescribe specific modelling approaches.

4. **Contract completeness** — For published interfaces (tables consumed by multiple teams), is there documentation of schema stability, quality expectations, and change management process?
   Are there stability labels (stable/experimental) on fields?

5. **Deadly diamond check** — Are there DAG paths where the same source data reaches the same target via multiple independent routes with different processing times?
   Are all upstream dependencies gated on completing the same partition before the target is written?

6. **Naming consistency** — Are naming conventions consistent within the table and across related tables?
   Can a consumer predict column names without consulting documentation?

## Severity Framing

Severity for Architecture findings is about the **structural consequence** to data consumers.

- **Schema drift findings** — How many consumers are affected? Is the change breaking or additive?
  Breaking changes on widely-consumed tables are HIGH / HYG.
  Naming inconsistency on internal-only tables is MEDIUM / L1.
- **Contract gaps** — Is this table consumed by multiple teams without a contract?
  Missing contracts are MEDIUM / L2 unless breaking changes are already happening.
- **Deadly diamond** — Does the dual-path corruption feed financial reporting or regulated data?
  Escalate to HYG if so.
