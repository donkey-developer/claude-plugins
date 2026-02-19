# SRE domain report omits required "What's Good" section

**Issue:** #53
**Branch:** fix/sre-whats-good
**Depends on:** none
**Brief ref:** BRIEF.md Section 1

## Tasks

- [x] **TASK-01: Read and understand the current SRE prompts**
  - **Goal:** Understand what the SRE `_base.md` currently specifies for output format, and how the other domain `_base.md` files define the "What's Good" section, so the fix can be applied consistently
  - **Brief ref:** BRIEF.md Section 1
  - **Files:**
    - Read `plugins/donkey-review/prompts/sre/_base.md`
    - Read `plugins/donkey-review/prompts/security/_base.md` (reference — already has "What's Good")
    - Read `plugins/donkey-review/prompts/architecture/_base.md` (reference — already has "What's Good")
    - Read `spec/review-standards/design-principles.md` (Principle 4)
  - **Verification:** You can identify exactly where in `sre/_base.md` the output format section lives, and you know the exact wording pattern used in the other domain base files

- [x] **TASK-02: Add "What's Good" requirement to `sre/_base.md`**
  - **Goal:** Add a "What's Good" section requirement to the SRE output format definition, parallel to the equivalent instruction in the security and architecture base files. The section must require specific code evidence (file references), not generic praise
  - **Brief ref:** BRIEF.md Section 1
  - **Files:** `plugins/donkey-review/prompts/sre/_base.md`
  - **Verification:** `plugins/donkey-review/prompts/sre/_base.md` now contains a "What's Good" output requirement with the same structure and specificity as the security and architecture equivalents

- [x] **TASK-03: Recompile agents and skills**
  - **Goal:** Regenerate all compiled agents and skills so they reflect the updated `sre/_base.md`
  - **Brief ref:** BRIEF.md — Verification
  - **Files:** Run `./scripts/compile.sh` from `plugins/donkey-review/`
  - **Verification:** `./scripts/compile.sh --check` exits 0 — no compiled files are out of sync with their prompt sources

- [x] **TASK-04: Final verification**
  - **Goal:** Confirm all deliverables for this issue are present and correct
  - **Verification:**
    - `plugins/donkey-review/prompts/sre/_base.md` contains a "What's Good" section requirement
    - `plugins/donkey-review/agents/sre-availability.md` contains the updated "What's Good" instruction
    - `plugins/donkey-review/agents/sre-observability.md` contains the updated instruction
    - `plugins/donkey-review/agents/sre-response.md` contains the updated instruction
    - `plugins/donkey-review/agents/sre-delivery.md` contains the updated instruction
    - `plugins/donkey-review/skills/sre/SKILL.md` reflects the updated synthesis section if it was changed
    - `./scripts/compile.sh --check` exits 0
