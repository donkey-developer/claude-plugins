# Cross-domain attributions appear inside domain reports

**Issue:** #55
**Branch:** fix/cross-domain-attributions
**Depends on:** #54 (fix/security-tool-prescriptions must be merged first — both regenerate security agents)
**Brief ref:** BRIEF.md Section 4

## Tasks

- [x] **TASK-01: Read current shared constraints and domain base files**
  - **Goal:** Determine precisely where the cross-domain attribution constraint should live — whether in `shared/constraints.md` (which applies to all agents), in domain-specific `_base.md` files, in `shared/synthesis.md` (which affects skills), or in a combination — so the fix is applied at the right layer
  - **Brief ref:** BRIEF.md Section 4
  - **Files:**
    - Read `plugins/donkey-review/prompts/shared/constraints.md`
    - Read `plugins/donkey-review/prompts/shared/synthesis.md`
    - Read `plugins/donkey-review/prompts/security/_base.md` (post-#54 state)
    - Read `plugins/donkey-review/prompts/architecture/_base.md`
    - Read `spec/review-standards/review-framework.md` (Universal Constraints — no cross-domain findings)
  - **Verification:** You can state which file(s) need to be updated and why, and confirm that the chosen location(s) will be compiled into the affected agents

- [x] **TASK-02: Add cross-domain attribution prohibition**
  - **Goal:** Add an explicit rule prohibiting domain agents from referencing sibling domain names or attributing findings as "(cross-domain)" within their own report. Pillar credits must list only pillars from that domain's own framework. Cross-domain themes belong exclusively in `summary.md` via the synthesis step
  - **Brief ref:** BRIEF.md Section 4
  - **Files:** `plugins/donkey-review/prompts/shared/constraints.md` and/or the domain `_base.md` files, as determined in TASK-01
  - **Verification:** The updated file(s) contain an unambiguous rule prohibiting sibling-domain references within a domain report, with the evidence cases from the issue as illustrative examples

- [x] **TASK-03: Recompile agents and skills**
  - **Goal:** Regenerate all compiled agents and skills so they reflect the updated prompt sources
  - **Brief ref:** BRIEF.md — Verification
  - **Files:** Run `./scripts/compile.sh` from `plugins/donkey-review/`
  - **Verification:** `./scripts/compile.sh --check` exits 0

- [x] **TASK-04: Final verification**
  - **Goal:** Confirm all deliverables for this issue are present and correct
  - **Verification:**
    - The relevant prompt source file(s) contain the cross-domain attribution prohibition
    - All four `agents/security-*.md` files contain the prohibition
    - All four `agents/architecture-*.md` files contain the prohibition
    - `./scripts/compile.sh --check` exits 0
