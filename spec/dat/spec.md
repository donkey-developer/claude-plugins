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

| Who | Uses the spec for |
|-----|-------------------|
| **Autonomous coding agents** | Building/modifying prompt files, agent definitions, skill orchestrators |
| **Human prompt engineers** | Reviewing agent output, calibrating severity, refining checklists |
| **Plugin consumers** | Understanding what the Data review evaluates and why |

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

The Data domain manifests as these files within the plugin:

```
donkey-dev/
  agents/
    data-architecture.md     # Subagent: schema design, domain boundaries, data contracts
    data-engineering.md      # Subagent: transformation correctness, performance, error handling
    data-quality.md          # Subagent: freshness SLOs, validation, documentation
    data-governance.md       # Subagent: compliance, lifecycle, ownership, lineage
  prompts/data/
    _base.md                 # Shared context: pillars, glossary, maturity model, output format
    architecture.md          # Architecture pillar checklist
    engineering.md           # Engineering pillar checklist
    quality.md               # Quality pillar checklist
    governance.md            # Governance pillar checklist
  skills/
    review-data/SKILL.md     # Orchestrator: scope, parallel dispatch, synthesis, output
```

### Composition rules

1. **Each agent file is self-contained.** It embeds the full content of `_base.md` + its pillar prompt. Agents do not reference external files at runtime -- all context must be inlined.
2. **Prompts are the source of truth.** The `prompts/data/` directory contains the human-readable, LLM-agnostic checklists. Agent files are compiled from these.
3. **The skill orchestrator dispatches and synthesises.** It does not contain review logic -- that lives in the agents.

### When modifying files

| Change type | Files to update |
|-------------|-----------------|
| Add/change a checklist item | `prompts/data/<pillar>.md` then recompile the corresponding `agents/data-<pillar>.md` |
| Change shared context (severity, maturity, output format) | `prompts/data/_base.md` then recompile ALL 4 agent files |
| Change orchestration logic | `skills/review-data/SKILL.md` only |
| Add a new pillar | New prompt file, new agent file, update SKILL.md to spawn 5th agent |

## 5. Design Principles

These principles govern all prompt changes in the Data domain. They align with the cross-domain principles established in PRs #18 and #19 and must be preserved.

### 5.1 Outcomes over techniques

Maturity criteria describe **observable outcomes**, not named techniques, patterns, or tools.

| Bad (technique) | Good (outcome) |
|-----------------|----------------|
| "Uses dbt" | "Pipeline dependencies are declared and acyclic" |
| "Implements Great Expectations" | "Input data is validated with automated checks" |
| "Follows Data Mesh" | "Each data asset has a defined owner and published interface" |
| "Uses star schema" | "Schema design is appropriate for the access pattern" |
| "Has a data catalog" | "Data assets are discoverable without tribal knowledge" |

**Rationale (PR #19):** Technique names create false negatives -- a team using SQLMesh satisfies "pipeline dependencies are declared" but wouldn't match "uses dbt". Outcomes are technology-neutral and verifiable from code.

### 5.2 Questions over imperatives

Checklists use questions to prompt investigation, not imperatives to demand compliance.

| Bad (imperative) | Good (question) |
|-------------------|-----------------|
| "Document all schemas" | "Can a new team member understand this data without asking someone?" |
| "Add freshness SLOs" | "Is there a defined expectation for when this data should be available?" |
| "Classify all PII" | "If this data was leaked, what would be the impact?" |
| "Implement lineage tracking" | "Can we trace this data back to its original source?" |

**Rationale:** Questions guide the reviewer to investigate the code and form a judgement. Imperatives produce binary "present/absent" assessments that miss nuance.

### 5.3 Concrete anti-patterns with code examples

Anti-pattern descriptions include specific code-level examples (SQL, Python, dbt), not abstract categories.

| Bad (abstract) | Good (concrete) |
|-----------------|-----------------|
| "Poor data quality" | "Silent type coercion: `pd.to_numeric(df['amount'], errors='coerce')` -- invalid values become NaN with no logging" |
| "Schema issue" | "Breaking change: `ALTER TABLE users RENAME COLUMN user_name TO username` -- all downstream consumers break immediately" |
| "Missing governance" | "PII in analytics: `df[['user_id', 'email', 'phone']].to_parquet('s3://analytics-bucket/')` -- raw PII in analytics layer" |

### 5.4 Positive observations required

Every review MUST include a "What's Good" section. Reviews that only list problems are demoralising and less actionable. Positive data patterns give teams confidence about what to preserve -- well-designed schemas, good test coverage, clear documentation, proper governance.

### 5.5 Hygiene gate is consequence-based

The Hygiene gate uses three consequence-severity tests (Irreversible, Total, Regulated), not domain-specific checklists. This ensures consistent escalation logic across all domains.

### 5.6 Severity is about data impact

| Level | Definition | Decision |
|-------|-----------|----------|
| **HIGH** | Data corruption, compliance violation, or consumer-breaking change | Must fix before merge |
| **MEDIUM** | Quality degradation, performance issue, or missing documentation | May require follow-up ticket |
| **LOW** | Style improvement or minor optimisation | Nice to have |

Severity measures the **data consequence** if the code ships as-is -- how will consumers be affected, can trust be maintained, is compliance at risk. Not how hard the fix is.

### 5.7 Consumer-first perspective

Data reviews evaluate from the **consumer's perspective**. The primary question is always: "How will downstream consumers experience this data?"

| Concern | Consumer perspective | Producer perspective (avoid) |
|---------|---------------------|------------------------------|
| Schema change | "Will this break my queries?" | "I needed to rename this column" |
| Quality | "Can I trust these numbers?" | "The pipeline ran without errors" |
| Freshness | "Is this data current enough for my decision?" | "The job runs every hour" |
| Documentation | "Can I use this without asking someone?" | "The code is self-documenting" |

### 5.8 Fail-safe defaults

Data handling should be **explicit, not silent**. When a data pipeline encounters unexpected input, the correct behaviour is to fail visibly, not to silently drop or coerce records. Silent data loss is worse than a noisy failure because it erodes trust without anyone knowing.

## 6. Orchestration Process

The `/review-data` skill follows this process:

### Step 1: Scope identification

- File or directory argument: review that path
- Empty or ".": review recent changes (`git diff`) or prompt for scope
- Focus on: SQL files, Python/Spark data processing, dbt models, pipeline definitions, schema files, migration scripts

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

1. **Collect** findings from all 4 pillars
2. **Deduplicate** -- when two agents flag the same `file:line`, merge into one finding:
   - Take the **highest severity**
   - Take the **most restrictive maturity level** (HYG > L1 > L2 > L3)
   - Combine recommendations from both agents
   - Credit both pillars in the Pillar column (e.g., "Architecture / Quality")
3. **Aggregate maturity** -- merge per-criterion assessments into one view:
   - All criteria met = `pass`
   - Mix of met and not met = `partial`
   - All criteria not met = `fail`
   - Previous level not passed = `locked`
4. **Prioritise** -- HYG findings first, then by severity (HIGH > MEDIUM > LOW)

### Step 4: Output

Produce the maturity assessment report per the output format defined in `_base.md`.

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

Things the Data domain deliberately does NOT do:

- **No auto-fix.** The review is read-only. Agents have Read, Grep, Glob tools only -- no Bash, no Write, no Edit.
- **No cross-domain findings.** Data does not flag architecture, SRE, or security issues. Those belong to their respective domains. Overlaps are intentional (e.g., PII handling is flagged by both Data/Governance and Security/Data-Protection, each through their own lens).
- **No numeric scores.** Status is pass/partial/fail/locked. No percentages, no weighted scores, no "data quality index".
- **No prescribing specific tools.** Never recommend a specific library, framework, or vendor. Describe the outcome, let the team choose the implementation. Say "input data is validated with automated checks", not "use Great Expectations".
- **No prescribing specific modelling approaches.** Do not require "star schema" or "3NF" or "Data Vault". Describe the structural property the data should exhibit for its use case. The team may achieve it through any approach.
- **No fabricating findings.** If a pillar doesn't apply (e.g., no PII in the reviewed code means Governance/Privacy has nothing to report), return "no findings" -- do not invent concerns to fill the report.
