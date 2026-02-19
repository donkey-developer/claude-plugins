# Security report recommends specific tools and libraries

**Issue:** #54
**Branch:** fix/security-tool-prescriptions
**Depends on:** #56 (fix/security-exploit-paths must be merged first — both modify `prompts/security/_base.md`)
**Brief ref:** BRIEF.md Section 3

## Tasks

- [x] **TASK-01: Read current security prompt and spec constraint**
  - **Goal:** Understand what `prompts/security/_base.md` currently says about tool/library recommendations, and confirm the exact spec constraint, so the fix adds only what is missing without duplicating existing rules
  - **Brief ref:** BRIEF.md Section 3
  - **Files:**
    - Read `plugins/donkey-review/prompts/security/_base.md` (as it stands on the base branch for this issue, i.e. after #56 merges)
    - Read `plugins/donkey-review/prompts/shared/constraints.md` (universal constraints — "no prescribing specific tools")
    - Read `spec/review-standards/review-framework.md` (Universal Constraints section)
  - **Verification:** You know whether the "no specific tools" rule is already in `shared/constraints.md` and therefore already compiled into all agents, or whether it needs to be reinforced in `security/_base.md` with security-specific examples

- [x] **TASK-02: Add explicit tool-prescription prohibition with before/after examples to `security/_base.md`**
  - **Goal:** Add an explicit prohibition against naming specific libraries, functions, or exact thresholds in fix-direction text. Include a security-specific before/after example showing outcome-phrased vs tool-phrased recommendations, as called for in the issue body
  - **Brief ref:** BRIEF.md Section 3
  - **Files:** `plugins/donkey-review/prompts/security/_base.md`
  - **Verification:** `security/_base.md` contains:
    - An explicit statement that fix directions must not name specific functions, libraries, or numeric thresholds
    - At least one before/after example (tool-phrased → outcome-phrased) drawn from the issue evidence

- [x] **TASK-03: Recompile agents and skills**
  - **Goal:** Regenerate all compiled agents and skills so they reflect the updated `security/_base.md`
  - **Brief ref:** BRIEF.md — Verification
  - **Files:** Run `./scripts/compile.sh` from `plugins/donkey-review/`
  - **Verification:** `./scripts/compile.sh --check` exits 0

- [ ] **TASK-04: Final verification**
  - **Goal:** Confirm all deliverables for this issue are present and correct
  - **Verification:**
    - `plugins/donkey-review/prompts/security/_base.md` contains a tool-prescription prohibition with before/after examples
    - All four `agents/security-*.md` files contain the updated instruction
    - `./scripts/compile.sh --check` exits 0
