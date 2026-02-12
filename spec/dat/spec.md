# Data Domain Specification

> Canonical reference for building, improving, and maintaining the Data review domain within the donkey-dev Claude Code plugin.

## 1. Purpose

The Data review domain evaluates code changes through the lens of data product quality. It answers one question: **"If we ship this, will the data be trusted and timely?"**

The domain produces a structured maturity assessment that tells engineering leaders:
- What data integrity risks exist right now (Hygiene failures)
- What foundational data practices are missing (L1 gaps)
- What operational data maturity looks like for this codebase (L2 criteria)
- What excellence would require (L3 aspirations)

Data focuses on the **lifecycle of data as a product** -- from schema design through transformation, quality assurance, and governance. It complements the Architecture domain (structural design), SRE domain (run-time reliability), and Security domain (threat exposure).

The guiding mantra is **Trusted and Timely**: data products must be accurate, well-governed, and available when consumers need them.

## 2. Audience

This domain inherits the shared audience definitions (see `../review-standards/review-framework.md`).

## 3. Conceptual Architecture

The Data domain is built from three interlocking layers:

```
+----------------------------------------------+
|        Four Pillars (Structure)               |   Organises WHAT to review
|  Architecture . Engineering .                 |
|  Quality . Governance                         |
+----------------------------------------------+
|  Quality Dimensions <--> Decay Patterns       |   Analytical LENSES
|  "What makes data       "How does data        |
|   trustworthy?"          go wrong?"           |
+----------------------------------------------+
|         Maturity Model (Judgement)             |   Calibrates SEVERITY
|    Hygiene --> L1 --> L2 --> L3                |   and PRIORITY
+----------------------------------------------+
```

- **The Four Pillars** provide the structural decomposition (4 pillars, 4 subagents). Each pillar examines data from a different concern -- design, code, quality, and compliance.
- **Quality Dimensions** and **Decay Patterns** provide the analytical duality. Quality Dimensions (from DAMA DMBOK) describe the measurable properties of trustworthy data; Decay Patterns describe how data products erode over time. See `framework-map.md` for the complete mapping.
- **The Maturity Model** provides the judgement framework for prioritising findings.

These layers are defined in detail in the companion files:
- `glossary.md` -- canonical definitions
- `framework-map.md` -- how pillars, quality dimensions, and decay patterns relate
- `maturity-criteria.md` -- detailed criteria with "sufficient" thresholds
- `calibration.md` -- worked examples showing severity judgement
- `anti-patterns.md` -- concrete code smells per pillar
- `references.md` -- source attribution

## 4. File Layout

This domain inherits the shared plugin file layout (see `../review-standards/review-framework.md`). Domain-specific files:

| Location | File | Purpose |
|----------|------|---------|
| `agents/` | `data-architecture.md` | Subagent: schema design, domain boundaries, data contracts |
| `agents/` | `data-engineering.md` | Subagent: transformation correctness, performance, error handling |
| `agents/` | `data-quality.md` | Subagent: freshness SLOs, validation, documentation |
| `agents/` | `data-governance.md` | Subagent: compliance, lifecycle, ownership, lineage |
| `prompts/data/` | `_base.md` | Shared context: pillars, glossary, maturity model, output format |
| `prompts/data/` | `architecture.md` | Architecture pillar checklist |
| `prompts/data/` | `engineering.md` | Engineering pillar checklist |
| `prompts/data/` | `quality.md` | Quality pillar checklist |
| `prompts/data/` | `governance.md` | Governance pillar checklist |
| `skills/` | `review-data/SKILL.md` | Orchestrator: scope, parallel dispatch, synthesis, output |

## 5. Design Principles

This domain inherits the shared design principles (see `../review-standards/design-principles.md`) and adds domain-specific principles and examples below.

### 5.1 Outcomes over techniques (domain examples)

| Bad (technique) | Good (outcome) |
|-----------------|----------------|
| "Uses dbt" | "Pipeline dependencies are declared and acyclic" |
| "Implements Great Expectations" | "Input data is validated with automated checks" |
| "Follows Data Mesh" | "Each data asset has a defined owner and published interface" |
| "Uses star schema" | "Schema design is appropriate for the access pattern" |
| "Has a data catalog" | "Data assets are discoverable without tribal knowledge" |

### 5.2 Questions over imperatives (domain examples)

| Bad (imperative) | Good (question) |
|-------------------|-----------------|
| "Document all schemas" | "Can a new team member understand this data without asking someone?" |
| "Add freshness SLOs" | "Is there a defined expectation for when this data should be available?" |
| "Classify all PII" | "If this data was leaked, what would be the impact?" |
| "Implement lineage tracking" | "Can we trace this data back to its original source?" |

### 5.3 Concrete anti-patterns (domain examples)

| Bad (abstract) | Good (concrete) |
|-----------------|-----------------|
| "Poor data quality" | "Silent type coercion: `pd.to_numeric(df['amount'], errors='coerce')` -- invalid values become NaN with no logging" |
| "Schema issue" | "Breaking change: `ALTER TABLE users RENAME COLUMN user_name TO username` -- all downstream consumers break immediately" |
| "Missing governance" | "PII in analytics: `df[['user_id', 'email', 'phone']].to_parquet('s3://analytics-bucket/')` -- raw PII in analytics layer" |

### 5.4 Severity is about data impact

| Level | Definition | Decision |
|-------|-----------|----------|
| **HIGH** | Data corruption, compliance violation, or consumer-breaking change | Must fix before merge |
| **MEDIUM** | Quality degradation, performance issue, or missing documentation | May require follow-up ticket |
| **LOW** | Style improvement or minor optimisation | Nice to have |

Severity measures the **data consequence** if the code ships as-is -- how will consumers be affected, can trust be maintained, is compliance at risk. Not how hard the fix is.

### 5.5 Consumer-first perspective

Data reviews evaluate from the **consumer's perspective**. The primary question is always: "How will downstream consumers experience this data?"

| Concern | Consumer perspective | Producer perspective (avoid) |
|---------|---------------------|------------------------------|
| Schema change | "Will this break my queries?" | "I needed to rename this column" |
| Quality | "Can I trust these numbers?" | "The pipeline ran without errors" |
| Freshness | "Is this data current enough for my decision?" | "The job runs every hour" |
| Documentation | "Can I use this without asking someone?" | "The code is self-documenting" |

### 5.6 Fail-safe defaults

Data handling should be **explicit, not silent**. When a data pipeline encounters unexpected input, the correct behaviour is to fail visibly, not to silently drop or coerce records. Silent data loss is worse than a noisy failure because it erodes trust without anyone knowing.

## 6. Orchestration Process

The `/review-data` skill follows the shared orchestration pattern (see `../review-standards/orchestration.md`) with these domain-specific details:

### Step 1: Scope identification (domain-specific addition)

In addition to the shared scoping algorithm, focus on: SQL files, Python/Spark data processing, dbt models, pipeline definitions, schema files, migration scripts.

### Step 2: Parallel dispatch

Spawn 4 subagents simultaneously:

| Agent | Model | Rationale |
|-------|-------|-----------|
| `data-architecture` | sonnet | Nuanced judgement on schema design, domain boundaries, and contract completeness |
| `data-engineering` | sonnet | Complex analysis of transformation correctness, idempotency, and performance |
| `data-quality` | sonnet | Subtle assessment of freshness, validation coverage, and documentation adequacy |
| `data-governance` | sonnet | Nuanced compliance analysis, PII identification, lifecycle management assessment |

**Model selection rationale:** All four Data agents use sonnet because data review requires nuanced judgement at every level. Unlike some SRE pillars where criteria are more binary, all data pillars require interpreting code against contextual quality expectations -- is this schema appropriate for the use case, is this transformation correct for the business logic, is this governance sufficient for the data classification.

### Step 3: Synthesis

Follows the shared synthesis algorithm (see `../review-standards/orchestration.md`). No domain-specific synthesis additions.

## 7. Improvement Vectors

Known gaps that future work should address, in priority order:

| # | Gap | Impact | Direction |
|---|-----|--------|-----------|
| 1 | **Quality Dimensions not explicitly mapped to pillars** | Reviewers don't systematically verify each quality dimension | Add explicit mapping: "this pillar is responsible for these quality dimensions" (see `framework-map.md`) |
| 2 | **No calibration examples** | Severity judgements are inconsistent -- the same missing freshness SLO might be HIGH in one review and MEDIUM in another | Add worked examples per severity per pillar (see `calibration.md`) |
| 3 | **L1 "sufficient" is undefined** | "Schemas are documented with field-level descriptions" is subjective -- what counts as sufficient documentation? | Define minimum thresholds (see `maturity-criteria.md`) |
| 4 | **Decay Patterns not codified** | The analytical duality is implicit -- anti-patterns exist but aren't classified by decay mechanism | Formalise decay pattern taxonomy and map to quality dimension defences (see `framework-map.md`) |
| 5 | **No technology-specific supplements** | Checklists can't recognise framework-specific patterns (dbt vs SQLMesh vs Airflow vs Spark) | Future: add optional supplements for dbt, Spark, Airflow, Dagster, BigQuery, Snowflake |
| 6 | **Governance assessment is document-heavy** | Governance agent sometimes expects policy documents rather than looking for evidence in code | Refine to focus on code evidence: TTL columns, partition expiration, soft-delete flags, access controls in DDL |
| 7 | **No streaming data patterns** | Checklists are batch-oriented; streaming-specific concerns (watermarks, late data, exactly-once semantics) are underrepresented | Future: add streaming supplement covering Kafka, Flink, event sourcing patterns |
| 8 | **No cross-review learning** | Each review is stateless | Future: use `.code-review/` history to track data maturity progression |

## 8. Constraints

This domain inherits the universal constraints (see `../review-standards/review-framework.md`) and adds:

- **No prescribing specific modelling approaches.** Do not require "star schema" or "3NF" or "Data Vault". Describe the structural property the data should exhibit for its use case. The team may achieve it through any approach.
- **No fabricating findings.** If a pillar doesn't apply (e.g., no PII in the reviewed code means Governance/Privacy has nothing to report), return "no findings" -- do not invent concerns to fill the report.
