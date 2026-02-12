# Glossary -- Data Domain

> Canonical definitions for all terms, frameworks, and acronyms used in the Data review domain. When writing or modifying prompts, use these definitions exactly.
>
> This glossary covers domain-specific terminology. For shared terms (maturity model, orchestration, output), see `../review-standards/glossary.md`.

## Frameworks

### The Four Pillars

The structural framework that organises the Data review into four pillars, each with a dedicated subagent. Synthesised from DAMA DMBOK, Data Mesh, and Data Governance for Everyone.

| Pillar | One-line mandate |
|--------|-----------------|
| **Architecture** | Is the data designed right? |
| **Engineering** | Is the data built right? |
| **Quality** | Does the data meet expectations? |
| **Governance** | Is the data managed right? |

### Quality Dimensions (DAMA DMBOK)

Six measurable properties of trustworthy data. These are the "defensive" lens -- they describe **what makes data trustworthy**.

| Dimension | Definition | Primary pillar |
|-----------|-----------|----------------|
| **Accuracy** | Data matches real-world truth | Quality |
| **Completeness** | All required data is present | Quality |
| **Consistency** | Same data across systems | Architecture |
| **Timeliness** | Data available when needed | Quality |
| **Validity** | Data conforms to business rules and constraints | Engineering |
| **Uniqueness** | No unintended duplicates | Engineering |

### Decay Patterns

Five mechanisms by which data products degrade over time. These are the "offensive" lens -- they describe **how data goes wrong in production**.

| Pattern | Definition | Recognition heuristic |
|---------|-----------|----------------------|
| **Silent corruption** | Data errors that propagate undetected, producing wrong results that consumers trust. | Look for: type coercion with `errors='coerce'`, fan-out joins without aggregation guards, NULL handling in JOINs that silently drops rows, missing validation on inbound data. |
| **Schema drift** | Gradual divergence between the actual schema and what consumers expect, causing breakage or misinterpretation. | Look for: column renames without versioning, semantic changes to existing fields, naming inconsistencies, missing data contracts, no schema change detection. |
| **Ownership erosion** | Loss of accountability over data assets, leading to orphaned datasets that nobody maintains. | Look for: no owner metadata, undocumented business rules (magic numbers), no catalog registration, no contact for questions. |
| **Freshness degradation** | Data falling behind real-world events, causing decisions based on stale information. | Look for: no freshness SLOs, no `loaded_at` timestamps, batch processing when near-real-time is needed, no alerting on processing delays. |
| **Compliance drift** | Governance controls weakening over time, creating regulatory exposure. | Look for: PII in logs or analytics without masking, no retention policies, tables growing forever, no Right-to-be-Forgotten mechanism, missing data classification. |

### Decay Pattern -- Quality Dimension Duality

Every decay pattern has corresponding quality dimensions that defend against it. When a reviewer identifies a decay pattern problem, they should recommend strengthening the corresponding quality dimensions. See `framework-map.md` for the complete mapping.

## Domain Concepts

| Term | Definition |
|------|-----------|
| **Data Product** | A self-contained, discoverable data asset with defined interfaces, quality guarantees, and ownership. The unit of data delivery in a Data Mesh architecture. |
| **Bounded Context** | A domain boundary where a particular data model applies. Crossing boundaries requires explicit mapping through published interfaces, not direct table access. |
| **Polyseme** | A shared concept (like 'User', 'Product', 'Order') that exists across domain boundaries and needs global identifiers for interoperability. Without global identifiers, cross-domain joins are fragile or impossible. |
| **Data Contract** | A formal agreement between a data producer and its consumers specifying: schema (fields, types, constraints), quality expectations (freshness, completeness), and SLAs (availability, latency). |
| **Consumer** | Any downstream system, team, or process that reads from a data product. The consumer's perspective is the primary lens for the Data review. |

## Data Modelling

| Term | Definition |
|------|-----------|
| **3NF (Third Normal Form)** | Normalised schema design for operational consistency and update anomaly prevention. Appropriate for OLTP/transactional workloads. |
| **Star/Snowflake Schema** | Denormalised schemas with fact tables and dimensions, optimised for analytical query performance. Appropriate for OLAP/analytical workloads. |
| **Bitemporality** | Recording both transaction time (when data was recorded in the system) and valid time (when the fact was true in reality). Essential for audit-critical data, handling late-arriving records, and supporting corrections. |
| **Wide Table** | A denormalised, feature-rich table optimised for ML feature access patterns. Appropriate for feature stores. |
| **Schema-on-Read** | Deferring schema enforcement to read time rather than write time. Appropriate for data lake raw layers where flexibility and late binding are prioritised. |

## Processing Patterns

| Term | Definition |
|------|-----------|
| **CDC (Change Data Capture)** | Capturing only changed records for efficient incremental processing. Avoids full table reprocessing for each pipeline run. |
| **Deadly Diamond** | A DAG pattern where data reaches a target via multiple independent paths, causing inconsistency (timing skew between paths) or metric inflation (multiple join paths to the same dimension). Mitigated by declaring all upstream paths as dependencies and gating on completion of all paths for the same partition. |
| **Idempotency** | Property where re-running a process with the same input produces the exact same output. Critical for data pipelines because re-runs are common (failure recovery, backfills, testing). |
| **Watermark** | A timestamp or version marker used to track processing progress for incremental loads. Enables the pipeline to know "where it left off" after an interruption. |
| **Fan-out** | A 1-to-many join that inflates row counts. When aggregating on the "one" side after a fan-out join, metrics are inflated. Mitigate by aggregating the "many" side first, then joining. |
| **Dead-letter Queue** | A destination for records that fail validation or processing. Preserves failed records for inspection and reprocessing rather than silently dropping them. |

## Quality and Observability

| Term | Definition |
|------|-----------|
| **Freshness SLO** | Service Level Objective defining acceptable delay between event occurrence and data availability. Example: "Data available within 15 minutes of event" or "Daily snapshot by 6am UTC". |
| **Event Time** | When something happened in the real world. Distinguished from processing time to detect and manage latency. |
| **Processing Time** | When the data pipeline processed the event. The gap between event time and processing time is the processing latency. |
| **Reconciliation** | Process of verifying data matches between source and target systems. Includes row count comparisons, sum/checksum verification, and sample record validation. |
| **Volume Monitoring** | Tracking expected row counts per load and alerting on anomalies (0 rows, 10x expected, 0.1x expected). |
| **Distribution Check** | Monitoring value distributions (mean/median shift, NULL percentage changes, cardinality changes) to detect data quality issues that pass row-count checks. |

## Governance

| Term | Definition |
|------|-----------|
| **Data Classification** | Categorisation of data by sensitivity: PII (Personally Identifiable Information), Confidential (business-sensitive), Internal (general business use), Public (safe to share externally). Classification determines required controls. |
| **Crypto-shredding** | Deleting encryption keys to make encrypted data irrecoverable. Used for Right-to-be-Forgotten compliance when data is distributed across many systems and direct deletion is impractical. |
| **RPO (Recovery Point Objective)** | Maximum acceptable data loss measured in time. "RPO of 1 hour" means the system must be recoverable to a state no more than 1 hour old. |
| **RTO (Recovery Time Objective)** | Maximum acceptable downtime. "RTO of 4 hours" means the system must be back online within 4 hours of a failure. |
| **Lineage** | The documented path of data from source to destination, including all transformations. Enables impact analysis ("if this source changes, what breaks?") and root cause analysis ("where did this bad data come from?"). |
| **Purpose Limitation** | Principle that data collection and processing should be limited to a specific, valid business purpose. A GDPR requirement. |

## Maturity Model

This domain inherits the shared maturity model (see `../review-standards/glossary.md` and `../review-standards/review-framework.md`).

Domain-specific maturity context:

| Level | One-line description |
|-------|---------------------|
| **L1** | Foundations -- The data can be understood and used. |
| **L2** | Hardening -- Production-ready practices. The data can be trusted and monitored. |
| **L3** | Excellence -- Best-in-class. The data is a model for others. |

### Hygiene Gate (domain examples)

| Test | Data examples |
|------|---------------|
| **Irreversible** | Pipeline silently drops records on schema mismatch (undetected data loss). Migration script with unbounded DELETE or TRUNCATE. Silent type coercion that converts invalid values to NULL without logging. |
| **Total** | Unbounded query that scans the full data warehouse (resource starvation for other users). Deadly diamond that corrupts a shared dimension used by all downstream consumers. |
| **Regulated** | PII written to application logs or analytics without masking. Missing Right-to-be-Forgotten mechanism for GDPR-covered data. Health data stored without encryption at rest. |

### Severity Levels

| Level | Data impact | Merge decision |
|-------|-------------|----------------|
| **HIGH** | Data corruption, compliance violation, or consumer-breaking change | Must fix before merge |
| **MEDIUM** | Quality degradation, performance issue, or missing documentation | May require follow-up ticket |
| **LOW** | Style improvement or minor optimisation | Nice to have |

Severity measures **data consequence**, not implementation difficulty.
