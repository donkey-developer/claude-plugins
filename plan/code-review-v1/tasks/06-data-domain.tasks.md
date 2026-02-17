# Create Data domain review

**Issue:** #23
**Branch:** feat/data-domain
**Depends on:** #19
**Brief ref:** BRIEF.md Sections 1-6

Follows the pattern established by the SRE reference implementation.

## Sources

- `spec/domains/data/spec.md` — Data specification index
- `spec/domains/data/anti-patterns.md` — anti-patterns with code examples
- `spec/domains/data/maturity-criteria.md` — Data-specific maturity criteria
- `spec/domains/data/framework-map.md` — Four Pillars framework mapping
- `spec/domains/data/glossary.md` — Data-specific terms
- `spec/domains/data/calibration.md` — calibration guidance
- Spike cross-reference (advisory): `https://github.com/LeeCampbell/code-review-llm` → `.claude/prompts/data/`

## Domain-specific notes

- **Four Pillars** — Architecture, Engineering, Quality, Governance
- **Guiding mantra:** "Trusted and Timely"
- **Quality Dimensions/Decay Patterns duality** — DAMA DMBOK dimensions (what makes data trustworthy?) vs Decay Patterns (how does data go wrong?)
- **Consumer-first perspective** — evaluate from downstream consumer perspective, not producer
- **Fail-safe defaults** — unexpected input should fail visibly, not silently drop/coerce
- **Do NOT prescribe modelling approaches** — describe structural properties, not "use star schema" or "3NF"
- **L2 has 5 criteria** (not 4 like other domains)
- **Data-specific file scoping** — SQL, dbt, Spark, pipeline configs, schema files, migration scripts
- **All 4 agents use sonnet** — contextual assessment of data fitness

## Tasks

- [x] **TASK-01: Create Data _base.md**
  - **Goal:** Distil the Data domain foundation into a base prompt covering Four Pillars, quality dimensions/decay patterns duality, maturity criteria, and glossary
  - **Brief ref:** BRIEF.md Section 6 (domain `_base.md`: ~200-250 lines)
  - **Files:**
    - Create `plugins/code-review/prompts/data/_base.md`
  - **Spec ref:** `spec/domains/data/spec.md`, `spec/domains/data/framework-map.md`, `spec/domains/data/maturity-criteria.md`, `spec/domains/data/glossary.md`
  - **Details:**
    - Purpose statement (what Data review evaluates)
    - Four Pillars overview (Architecture, Engineering, Quality, Governance)
    - "Trusted and Timely" mantra
    - Quality Dimensions/Decay Patterns duality
    - Consumer-first perspective principle
    - Fail-safe defaults principle
    - Domain-specific maturity criteria (note L2 has 5 criteria)
    - Data glossary
    - `## Review Instructions` section with Quality Dimensions/Decay Patterns lens names
    - `## Synthesis Pre-filter` section: data-specific file scoping (SQL, dbt, Spark, pipeline configs)
  - **Verification:** File exists; ~200-250 lines; covers Four Pillars, duality, consumer-first, fail-safe; has synthesis pre-filter

- [x] **TASK-02: Create Data architecture.md pillar prompt**
  - **Goal:** Create the Data Architecture pillar prompt with focus areas, anti-patterns, and checklist
  - **Brief ref:** BRIEF.md Section 6 (pillar prompts: ~80-120 lines)
  - **Files:**
    - Create `plugins/code-review/prompts/data/architecture.md`
  - **Spec ref:** `spec/domains/data/anti-patterns.md` (Architecture patterns), `spec/domains/data/calibration.md`
  - **Details:** Schema design, domain boundaries, contract completeness, data product boundaries. Describe structural properties, not modelling approaches.
  - **Verification:** File exists; ~80-120 lines; does NOT prescribe modelling approaches; has checklist

- [x] **TASK-03: Create Data engineering.md pillar prompt**
  - **Goal:** Create the Data Engineering pillar prompt with focus areas, anti-patterns, and checklist
  - **Files:**
    - Create `plugins/code-review/prompts/data/engineering.md`
  - **Spec ref:** `spec/domains/data/anti-patterns.md` (Engineering patterns), `spec/domains/data/calibration.md`
  - **Details:** Transformation correctness, idempotency, performance, pipeline reliability. Fail-safe defaults — silent data loss is a critical finding.
  - **Verification:** File exists; ~80-120 lines; has checklist

- [x] **TASK-04: Create Data quality.md pillar prompt**
  - **Goal:** Create the Data Quality pillar prompt with focus areas, anti-patterns, and checklist
  - **Files:**
    - Create `plugins/code-review/prompts/data/quality.md`
  - **Spec ref:** `spec/domains/data/anti-patterns.md` (Quality patterns), `spec/domains/data/calibration.md`
  - **Details:** Freshness SLOs, validation coverage, documentation adequacy, completeness, accuracy. Consumer-first — "how will consumers experience this data?"
  - **Verification:** File exists; ~80-120 lines; has checklist

- [x] **TASK-05: Create Data governance.md pillar prompt**
  - **Goal:** Create the Data Governance pillar prompt with focus areas, anti-patterns, and checklist
  - **Files:**
    - Create `plugins/code-review/prompts/data/governance.md`
  - **Spec ref:** `spec/domains/data/anti-patterns.md` (Governance patterns), `spec/domains/data/calibration.md`
  - **Details:** Compliance analysis, PII identification, lifecycle management, retention policies, access controls. Regulatory severity (GDPR, CCPA violations).
  - **Verification:** File exists; ~80-120 lines; has checklist

- [x] **TASK-06: Add Data entries to compile.conf**
  - **Goal:** Add the 4 Data agent entries and 1 Data skill entry to compile.conf
  - **Files:**
    - Edit `plugins/code-review/prompts/compile.conf`
  - **Details:**
    - `data-architecture`: model=sonnet
    - `data-engineering`: model=sonnet
    - `data-quality`: model=sonnet
    - `data-governance`: model=sonnet
    - `data` skill entry
  - **Verification:** compile.conf has 4 Data agent entries (all sonnet) and 1 Data skill entry

- [x] **TASK-07: Run compile.sh and verify generated files**
  - **Goal:** Generate the 4 Data agent files and the Data skill file from prompts
  - **Files generated:**
    - `plugins/code-review/agents/data-architecture.md`
    - `plugins/code-review/agents/data-engineering.md`
    - `plugins/code-review/agents/data-quality.md`
    - `plugins/code-review/agents/data-governance.md`
    - `plugins/code-review/skills/data/SKILL.md`
  - **Verification:**
    - `scripts/compile.sh` exits 0
    - All 5 files exist with correct frontmatter (all sonnet)
    - Data skill includes scope filter in synthesis rules
    - Consumer-first perspective present in agent prompts
    - No modelling approaches prescribed
    - `scripts/compile.sh --check` exits 0

- [ ] **TASK-08: Final verification**
  - **Goal:** Verify the complete Data domain is correctly built
  - **Verification:**
    - 5 prompt source files exist in `prompts/data/`
    - 4 agent files exist in `agents/` with correct frontmatter (all sonnet)
    - 1 skill file exists in `skills/data/SKILL.md`
    - Scope filter present in skill synthesis rules
    - Consumer-first and fail-safe defaults in agent prompts
    - No modelling approaches prescribed (grep for "star schema", "3NF", etc.)
    - `compile.sh --check` confirms sync
