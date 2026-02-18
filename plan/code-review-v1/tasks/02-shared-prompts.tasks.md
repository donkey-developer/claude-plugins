# Create shared cross-domain prompts

**Issue:** #19
**Branch:** feat/02-shared-prompts
**Depends on:** #18
**Brief ref:** BRIEF.md Sections 2, 5, 6

## Tasks

- [x] **TASK-01: Create maturity-model.md**
  - **Goal:** Distil the maturity model (Hygiene gate, L1/L2/L3, status indicators) into a concise prompt fragment
  - **Brief ref:** BRIEF.md Section 6 (prompt size targets — shared content ~180 lines total)
  - **Files:**
    - Create `plugins/code-review/prompts/shared/maturity-model.md`
  - **Spec ref:** `spec/review-standards/review-framework.md` — Maturity model section
  - **Details:** Include Hygiene gate rules (irreversible, total, regulated), level descriptions (L1/L2/L3), status indicators (pass/partial/fail/locked), promotion rules. Keep concise — this is inlined into every agent.
  - **Verification:** File exists; covers Hygiene gate, L1-L3 levels, status indicators; under 40 lines

- [ ] **TASK-02: Create severity-framework.md**
  - **Goal:** Distil the severity framework (HIGH/MEDIUM/LOW definitions) into a concise prompt fragment
  - **Files:**
    - Create `plugins/code-review/prompts/shared/severity-framework.md`
  - **Spec ref:** `spec/review-standards/review-framework.md` — Severity section
  - **Details:** HIGH (must fix before merge), MEDIUM (follow-up ticket), LOW (nice to have). Note that each domain contextualises severity around its own impact framing.
  - **Verification:** File exists; defines 3 severity levels with merge-decision guidance; under 25 lines

- [ ] **TASK-03: Create design-principles.md**
  - **Goal:** Distil the 5 core design principles into a concise prompt fragment
  - **Files:**
    - Create `plugins/code-review/prompts/shared/design-principles.md`
  - **Spec ref:** `spec/review-standards/design-principles.md`
  - **Details:** Outcomes over techniques, questions over imperatives, positive observations, consequence-based hygiene, and the fifth principle. Keep actionable — agents must apply these, not just know them.
  - **Verification:** File exists; captures all 5 principles; under 40 lines

- [ ] **TASK-04: Create output-format.md**
  - **Goal:** Define the standard output format for agent findings
  - **Files:**
    - Create `plugins/code-review/prompts/shared/output-format.md`
  - **Spec ref:** `spec/review-standards/review-framework.md` — Output format section
  - **Details:** Finding table columns, maturity table format, required sections (Summary, Findings, What's Good, Maturity Assessment). Include example templates.
  - **Verification:** File exists; defines finding table and maturity table formats; includes section headings; under 40 lines

- [ ] **TASK-05: Create constraints.md**
  - **Goal:** Define the hard constraints that apply to all agents
  - **Files:**
    - Create `plugins/code-review/prompts/shared/constraints.md`
  - **Spec ref:** `spec/review-standards/review-framework.md` — Constraints section
  - **Details:** Read-only (no auto-fix), no cross-domain findings, no numeric scores, no tool prescriptions. These are non-negotiable rules every agent must follow.
  - **Verification:** File exists; lists all constraints; under 20 lines

- [ ] **TASK-06: Create synthesis.md**
  - **Goal:** Define the synthesis algorithm used by skill orchestrators to combine pillar results
  - **Files:**
    - Create `plugins/code-review/prompts/shared/synthesis.md`
  - **Spec ref:** `spec/review-standards/orchestration.md` — Synthesis section
  - **Details:** Collect → deduplicate (same file:line → merge, highest severity, most restrictive maturity) → aggregate maturity → prioritise (HYG > HIGH > MED > LOW). Note placeholders for domain-specific pre-filters (Security confidence filter, Data scope filter). This file is inlined into every skill.
  - **Verification:** File exists; defines complete synthesis algorithm with dedup, aggregation, prioritisation; under 40 lines

- [ ] **TASK-07: Final verification**
  - **Goal:** Verify all 6 shared prompt files exist with appropriate content and size
  - **Verification:**
    - All 6 files exist in `plugins/code-review/prompts/shared/`
    - Total shared content is approximately 180 lines (within ±30 lines)
    - Each file is self-contained and reusable across all 4 domains
    - Run `scripts/compile.sh` — should execute without error (no agents to generate yet, but validates script finds shared prompts)
