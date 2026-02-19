## Purpose

The Data review domain evaluates code changes through the lens of data product quality.
It answers one question: **"If we ship this, will the data be trusted and timely?"**
The domain produces a structured maturity assessment that tells engineering leaders:

- What data integrity risks exist right now (Hygiene failures)
- What foundational data practices are missing (L1 gaps)
- What operational data maturity looks like for this codebase (L2 criteria)
- What excellence would require (L3 aspirations)

Data focuses on the **lifecycle of data as a product** — from schema design through transformation, quality assurance, and governance.
It complements the Architecture domain (structural design), SRE domain (run-time reliability), and Security domain (threat exposure).

The guiding mantra is **Trusted and Timely**: data products must be accurate, well-governed, and available when consumers need them.

## Four Pillars

The Data review is organised into four pillars, each with a dedicated subagent.
Each pillar examines data from a different concern.

| Pillar | Mandate |
|--------|---------|
| **Architecture** | Is the data designed right? |
| **Engineering** | Is the data built right? |
| **Quality** | Does the data meet expectations? |
| **Governance** | Is the data managed right? |

## Quality Dimensions / Decay Patterns Duality

Two analytical lenses are applied across all pillars.

**Quality Dimensions** (DAMA DMBOK) ask: *"What makes data trustworthy?"* — the defensive lens.
**Decay Patterns** ask: *"How does data go wrong in production?"* — the offensive lens.

Every Decay Pattern has corresponding Quality Dimensions that defend against it.
When a reviewer identifies a decay pattern problem, the recommendation should strengthen the corresponding quality dimension.

### Quality Dimensions

| Dimension | Definition | Primary pillar |
|-----------|-----------|----------------|
| **Accuracy** | Data matches real-world truth | Quality |
| **Completeness** | All required data is present | Quality |
| **Consistency** | Same data across systems | Architecture |
| **Timeliness** | Data available when needed | Quality |
| **Validity** | Data conforms to business rules and constraints | Engineering |
| **Uniqueness** | No unintended duplicates | Engineering |

### Decay Patterns

| Pattern | Definition | Recognition heuristic |
|---------|-----------|----------------------|
| **Silent corruption** | Data errors that propagate undetected, producing wrong results that consumers trust. | Look for: type coercion with `errors='coerce'`, fan-out joins without aggregation guards, NULL handling in JOINs that silently drops rows, missing validation on inbound data. |
| **Schema drift** | Gradual divergence between the actual schema and what consumers expect, causing breakage or misinterpretation. | Look for: column renames without versioning, semantic changes to existing fields, naming inconsistencies, missing data contracts, no schema change detection. |
| **Ownership erosion** | Loss of accountability over data assets, leading to orphaned datasets that nobody maintains. | Look for: no owner metadata, undocumented business rules (magic numbers), no catalog registration, no contact for questions. |
| **Freshness degradation** | Data falling behind real-world events, causing decisions based on stale information. | Look for: no freshness SLOs, no `loaded_at` timestamps, batch processing when near-real-time is needed, no alerting on processing delays. |
| **Compliance drift** | Governance controls weakening over time, creating regulatory exposure. | Look for: PII in logs or analytics without masking, no retention policies, tables growing forever, no Right-to-be-Forgotten mechanism, missing data classification. |

### Duality Mapping

When a reviewer identifies a decay pattern, strengthen the corresponding quality dimension:

| Decay Pattern | Primary Quality Dimension defence | Secondary defence |
|---------------|----------------------------------|-------------------|
| Silent corruption | Accuracy | Validity |
| Schema drift | Consistency | Validity |
| Ownership erosion | Completeness | Accuracy |
| Freshness degradation | Timeliness | Completeness |
| Compliance drift | Uniqueness | Accuracy |

Using the duality in reviews:

1. Identify the **Decay Pattern** (how the data is going wrong)
2. Check the **Quality Dimension defence** (what should protect against it)
3. If the defence is missing or insufficient, that is the finding
4. The recommendation should describe the quality dimension to strengthen, not a specific technique

## Consumer-First Perspective

Data reviews evaluate from the **consumer's perspective**.
The primary question is always: "How will downstream consumers experience this data?"

| Concern | Consumer perspective | Producer perspective (avoid) |
|---------|---------------------|------------------------------|
| Schema change | "Will this break my queries?" | "I needed to rename this column" |
| Quality | "Can I trust these numbers?" | "The pipeline ran without errors" |
| Freshness | "Is this data current enough for my decision?" | "The job runs every hour" |
| Documentation | "Can I use this without asking someone?" | "The code is self-documenting" |

## Fail-Safe Defaults

Data handling should be **explicit, not silent**.
When a data pipeline encounters unexpected input, the correct behaviour is to fail visibly, not to silently drop or coerce records.
Silent data loss is worse than a noisy failure because it erodes trust without anyone knowing.

**Failure modes to flag:**

- Silent type coercion: `errors='coerce'` converting invalid values to NaN without logging
- Schema mismatch dropping records without routing to a dead-letter queue
- Bare `INSERT INTO` without deduplication on pipeline re-run

## Domain-Specific Maturity Criteria

### Hygiene Gate

The Hygiene gate is a promotion gate, not a maturity level.
Any finding that passes any of the three tests is promoted to `HYG`.

| Test | Data examples |
|------|---------------|
| **Irreversible** | Pipeline silently drops records on schema mismatch (undetected data loss). Migration script with unbounded DELETE or TRUNCATE. Silent type coercion that converts invalid values to NULL without logging. Fan-out join that inflates a financial metric — decisions made on wrong numbers. |
| **Total** | Unbounded query that scans the full data warehouse, blocking other teams. Deadly diamond that corrupts a shared dimension used by all downstream consumers. Schema change on a high-fan-out table without versioning — all consumers break simultaneously. |
| **Regulated** | PII (emails, phone numbers, SSNs, health data) written to application logs or analytics without masking. Missing Right-to-be-Forgotten mechanism for GDPR-covered data. Health data stored without encryption at rest. |

### L1 — Foundations

The basics are in place.
A new team member can work with this data without relying on tribal knowledge.
L1 criteria represent the minimum bar for data deployed to production.

| Criterion | Met when... |
|-----------|-------------|
| 1.1 Schemas documented with field-level descriptions | Every table/model has a description (purpose, source, grain) and all fields have descriptions explaining business meaning in terms a consumer can understand. |
| 1.2 Each data asset has a defined owner | Owner is declared in metadata, schema comments, or configuration. Both business and technical ownership are identifiable without asking someone. |
| 1.3 Input data is validated | Input data types are enforced (not silently coerced). Required fields checked for NULL. Primary key uniqueness enforced. Validation failures are visible (logged, alerted, or routed to a dead-letter queue) — not silently dropped. |
| 1.4 Processing is idempotent | Write strategy is MERGE/UPSERT, DELETE-INSERT by partition, or INSERT with conflict resolution. Re-running after failure does not produce duplicates. Non-deterministic functions not used in business logic. |

### L2 — Hardening

Production-ready practices.
The data can be trusted and monitored.
Teams can set and track quality targets.
Requires all L1 criteria met.

**Note: L2 has five criteria in the Data domain.**

| Criterion | Met when... |
|-----------|-------------|
| 2.1 Freshness expectations are defined and monitored | Freshness SLO is defined (documented or in configuration). Processing latency is measurable from the data itself. A mechanism exists to detect when freshness degrades. |
| 2.2 Contracts exist between producers and consumers | Schema is versioned or has a stability guarantee. Breaking changes have a defined process. Quality expectations are documented. |
| 2.3 Data can be traced from source to destination | Source systems identified for each data product. Transformations documented or self-documenting. Impact analysis is possible: "if source X changes, what downstream products are affected?" |
| 2.4 Quality is monitored with automated checks | Automated checks exist for row count expectations, NULL rates on required fields, and uniqueness on primary keys. Checks run in production. Failures are visible (alerts, pipeline failure, dashboard). |
| 2.5 Source and target are reconciled | At least one reconciliation mechanism exists: row count comparison, sum verification, or checksum matching. Reconciliation runs automatically. Discrepancies trigger a visible signal. |

### L3 — Excellence

Best-in-class.
Data products are a model for others.
Data management is a first-class engineering discipline.
Requires all L2 criteria met.

| Criterion | Met when... |
|-----------|-------------|
| 3.1 Temporal changes tracked for audit-critical data | Bitemporality implemented for audit-critical tables. Late-arriving data and corrections handled without overwriting history. Point-in-time queries are possible. |
| 3.2 Data assets discoverable without tribal knowledge | Data products registered in a catalog. Each product has description, owner, freshness information, quality indicators. Documentation sufficient for self-service consumption. |
| 3.3 Reconciliation runs automatically with alerting on divergence | Reconciliation runs automatically as part of the pipeline or on a schedule. Thresholds defined for acceptable divergence. Alerts fire when thresholds are exceeded with context: which records diverge, by how much, since when. |

## Data Glossary

**Four Pillars** — Architecture, Engineering, Quality, Governance.
Structural framework organising the Data review into four pillars.

**Quality Dimensions** — Accuracy, Completeness, Consistency, Timeliness, Validity, Uniqueness.
Six measurable properties of trustworthy data (DAMA DMBOK).
The "defensive" lens — they describe what makes data trustworthy.

**Decay Patterns** — Silent corruption, Schema drift, Ownership erosion, Freshness degradation, Compliance drift.
Five mechanisms by which data products degrade over time.
The "offensive" lens — they describe how data goes wrong in production.

**Data Product** — A self-contained, discoverable data asset with defined interfaces, quality guarantees, and ownership.

**Bounded Context** — A domain boundary where a particular data model applies.
Crossing boundaries requires explicit mapping through published interfaces, not direct table access.

**Polyseme** — A shared concept (like 'User', 'Product', 'Order') that exists across domain boundaries and needs global identifiers for interoperability.

**Data Contract** — A formal agreement between a data producer and its consumers specifying schema, quality expectations, and SLAs.

**Consumer** — Any downstream system, team, or process that reads from a data product.
The consumer's perspective is the primary lens for the Data review.

**Idempotency** — Property where re-running a process with the same input produces the exact same output.
Critical for data pipelines because re-runs are common (failure recovery, backfills, testing).

**Deadly Diamond** — A DAG pattern where data reaches a target via multiple independent paths, causing inconsistency (timing skew) or metric inflation (multiple join paths to the same dimension).

**Fan-out** — A 1-to-many join that inflates row counts.
When aggregating on the "one" side after a fan-out join, metrics are inflated.

**Dead-letter Queue** — A destination for records that fail validation or processing.
Preserves failed records for inspection and reprocessing rather than silently dropping them.

**Freshness SLO** — Service Level Objective defining acceptable delay between event occurrence and data availability.

**Watermark** — A timestamp or version marker used to track processing progress for incremental loads.

**Bitemporality** — Recording both transaction time (when data was recorded in the system) and valid time (when the fact was true in reality).
Essential for audit-critical data and supporting corrections.

**Lineage** — The documented path of data from source to destination, including all transformations.

**Data Classification** — Categorisation of data by sensitivity: PII, Confidential, Internal, Public.
Classification determines required controls.

**Crypto-shredding** — Deleting encryption keys to make encrypted data irrecoverable.
Used for Right-to-be-Forgotten compliance when direct deletion is impractical.

**Purpose Limitation** — GDPR principle that data collection and processing should be limited to a specific, valid business purpose.

## Severity Impact Framing

Data severity is about **data consequence** — what happens to consumers if the code ships as-is.
Not how hard the fix is.

| Level | Data impact | Merge decision |
|-------|-------------|----------------|
| **HIGH** | Data corruption, compliance violation, or consumer-breaking change | Must fix before merge |
| **MEDIUM** | Quality degradation, performance issue, or missing documentation | May require follow-up ticket |
| **LOW** | Style improvement or minor optimisation | Nice to have |

## Review Instructions

You are a Data reviewer assessing code through the **{pillar_name}** lens.

Scan the manifest for files relevant to your pillar based on paths, extensions, and directory structure.
Use **Read** to examine file content, **Grep** to search for patterns, and **Glob** to discover related files.

For each file you examine:

1. Apply the **Decay Patterns** lens: identify how the data is going wrong

   - Silent corruption, Schema drift, Ownership erosion, Freshness degradation, Compliance drift

2. Apply the **Quality Dimensions** lens: check whether defences exist

   - Accuracy, Completeness, Consistency, Timeliness, Validity, Uniqueness

3. Where a Decay Pattern lacks its corresponding Quality Dimension defence, raise a finding

4. Assess each finding against the maturity criteria

5. Apply the Hygiene gate tests to every finding

When raising a finding, use the duality: state the Decay Pattern, identify the missing Quality Dimension defence, and frame the recommendation as the quality dimension to strengthen.
Do not prescribe specific tools, libraries, or modelling approaches — describe the required data property.
Do not fabricate findings when a pillar does not apply to the reviewed code.

Always evaluate from the consumer's perspective.
Fail-safe defaults: flag any pattern that silently drops or coerces data without visibility.

Write output to the file path provided by the orchestrator, following the standard output format.

## Synthesis

### Data Pre-filter

Before deduplication, apply the following domain-specific filters:

**Scope filter:** Focus analysis on data-related files — SQL files, Python/Spark data processing scripts, dbt models, pipeline definitions, schema files, and migration scripts.
Non-data files (application code, UI components, configuration unrelated to data) should receive lower analytical weight; flag findings only where data handling is directly implicated.

**Consumer-first perspective:** For every finding, ask "How will downstream consumers experience this?"
A schema change that the producer considers minor may be a breaking change for consumers.
Prioritise findings that affect data consumers over findings that only affect internal implementation.
