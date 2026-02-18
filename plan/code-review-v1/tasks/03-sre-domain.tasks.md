# Create SRE domain review

**Issue:** #20
**Branch:** feat/03-sre-domain
**Depends on:** #19
**Brief ref:** BRIEF.md Sections 1-6

This is the **reference implementation** — the first domain built, establishing the pattern for Security, Architecture, and Data.

## Sources

- `spec/domains/sre/spec.md` — SRE specification index
- `spec/domains/sre/anti-patterns.md` — anti-patterns with code examples
- `spec/domains/sre/maturity-criteria.md` — SRE-specific maturity criteria
- `spec/domains/sre/framework-map.md` — ROAD framework mapping
- `spec/domains/sre/glossary.md` — SRE-specific terms
- `spec/domains/sre/calibration.md` — calibration guidance
- Spike cross-reference (advisory): `https://github.com/LeeCampbell/code-review-llm` → `.claude/prompts/sre/`

## Tasks

- [x] **TASK-01: Create SRE _base.md**
  - **Goal:** Distil the SRE domain foundation into a base prompt covering ROAD framework, SEEMS/FaCTOR duality, maturity criteria, and glossary
  - **Brief ref:** BRIEF.md Section 6 (domain `_base.md`: ~200-250 lines)
  - **Files:**
    - Create `plugins/code-review/prompts/sre/_base.md`
  - **Spec ref:** `spec/domains/sre/spec.md`, `spec/domains/sre/framework-map.md`, `spec/domains/sre/maturity-criteria.md`, `spec/domains/sre/glossary.md`
  - **Details:**
    - Purpose statement (what SRE review evaluates)
    - ROAD framework overview (Response, Observability, Availability, Delivery)
    - SEEMS/FaCTOR duality (attack/defence lenses)
    - Domain-specific maturity criteria for each level (Hygiene, L1, L2, L3)
    - SRE glossary (key terms the agent needs)
    - `## Review Instructions` section with SEEMS/FaCTOR lens names
    - No domain-specific synthesis rules for SRE (note this explicitly)
  - **Verification:** File exists; ~200-250 lines; covers ROAD, SEEMS/FaCTOR, maturity criteria, glossary; has Review Instructions section

- [x] **TASK-02: Create SRE response.md pillar prompt**
  - **Goal:** Create the Response pillar prompt with focus areas, anti-patterns (RP-01..RP-06), and checklist
  - **Brief ref:** BRIEF.md Section 6 (pillar prompts: ~80-120 lines)
  - **Files:**
    - Create `plugins/code-review/prompts/sre/response.md`
  - **Spec ref:** `spec/domains/sre/anti-patterns.md` (RP-01 through RP-06), `spec/domains/sre/calibration.md`
  - **Details:** Pillar scope, anti-pattern catalogue with concise code examples, review checklist. Severity is about production consequence (error propagation, missing runbooks, unsafe retries).
  - **Verification:** File exists; ~80-120 lines; includes all RP anti-patterns; has checklist

- [ ] **TASK-03: Create SRE observability.md pillar prompt**
  - **Goal:** Create the Observability pillar prompt with focus areas, anti-patterns (OP-01..OP-07), and checklist
  - **Files:**
    - Create `plugins/code-review/prompts/sre/observability.md`
  - **Spec ref:** `spec/domains/sre/anti-patterns.md` (OP-01 through OP-07), `spec/domains/sre/calibration.md`
  - **Verification:** File exists; ~80-120 lines; includes all OP anti-patterns; has checklist

- [ ] **TASK-04: Create SRE availability.md pillar prompt**
  - **Goal:** Create the Availability pillar prompt with focus areas, anti-patterns (AP-01..AP-10), and checklist
  - **Files:**
    - Create `plugins/code-review/prompts/sre/availability.md`
  - **Spec ref:** `spec/domains/sre/anti-patterns.md` (AP-01 through AP-10), `spec/domains/sre/calibration.md`
  - **Verification:** File exists; ~80-120 lines; includes all AP anti-patterns; has checklist

- [ ] **TASK-05: Create SRE delivery.md pillar prompt**
  - **Goal:** Create the Delivery pillar prompt with focus areas, anti-patterns (DP-01..DP-09), and checklist
  - **Files:**
    - Create `plugins/code-review/prompts/sre/delivery.md`
  - **Spec ref:** `spec/domains/sre/anti-patterns.md` (DP-01 through DP-09), `spec/domains/sre/calibration.md`
  - **Verification:** File exists; ~80-120 lines; includes all DP anti-patterns; has checklist

- [ ] **TASK-06: Add SRE entries to compile.conf**
  - **Goal:** Add the 4 SRE agent entries and 1 SRE skill entry to compile.conf
  - **Files:**
    - Edit `plugins/code-review/prompts/compile.conf`
  - **Details:**
    - `sre-response`: model=sonnet, description references Response pillar
    - `sre-observability`: model=sonnet, description references Observability pillar
    - `sre-availability`: model=sonnet, description references Availability pillar
    - `sre-delivery`: model=haiku, description references Delivery pillar
    - `sre` skill: description references SRE domain review
  - **Verification:** compile.conf has 4 SRE agent entries with correct models and 1 SRE skill entry

- [ ] **TASK-07: Run compile.sh and verify generated files**
  - **Goal:** Generate the 4 SRE agent files and the SRE skill file from prompts
  - **Files generated:**
    - `plugins/code-review/agents/sre-response.md`
    - `plugins/code-review/agents/sre-observability.md`
    - `plugins/code-review/agents/sre-availability.md`
    - `plugins/code-review/agents/sre-delivery.md`
    - `plugins/code-review/skills/sre/SKILL.md`
  - **Verification:**
    - `scripts/compile.sh` exits 0
    - All 5 files exist
    - Each agent file has correct YAML frontmatter (name, description, model, tools)
    - Each agent file contains inlined shared + domain + pillar content
    - Skill file contains synthesis rules compiled from `synthesis.md`
    - `scripts/compile.sh --check` exits 0 (files are in sync)

- [ ] **TASK-08: Final verification**
  - **Goal:** Verify the complete SRE domain is correctly built and sets the reference pattern
  - **Verification:**
    - 5 prompt source files exist in `prompts/sre/`
    - 4 agent files exist in `agents/` with correct frontmatter and content
    - 1 skill file exists in `skills/sre/SKILL.md` with orchestrator logic and synthesis rules
    - Agent files are self-contained (grep for no `Read` of prompt files)
    - Total agent file sizes are within prompt size targets (~460-550 lines each)
    - `compile.sh --check` confirms sync
