# Close milestone: Review Output Conformance

**Issue:** #58
**Branch:** chore/close-review-output-conformance
**Depends on:** #53, #54, #55, #56 (all other issues in this milestone)
**Brief ref:** BRIEF.md (entire document — read as source material before updating specs)

## Tasks

- [x] **TASK-01: Update specs with new patterns**
  - **Goal:** Add any implementation patterns introduced during this milestone to the relevant spec files under `spec/`. Specifically: the "What's Good" requirement in SRE output format, the mandatory exploit-path rule for all security findings, the tool-prescription prohibition with examples, and the cross-domain attribution prohibition
  - **Files:**
    - `spec/domains/sre/spec.md` — "What's Good" output format requirement (if not already present)
    - `spec/domains/security/spec.md` — mandatory exploit path at all severities; tool-prescription prohibition with before/after examples
    - `spec/review-standards/review-framework.md` — cross-domain attribution prohibition with illustrative cases (if strengthened beyond current wording)
  - **Verification:** Each new pattern has a section in the appropriate spec file

- [x] **TASK-02: Capture decision rationale**
  - **Goal:** Extract rationale from `BRIEF.md` and implementation experience — trade-offs considered, alternatives rejected, constraints that drove decisions — and add to the relevant spec files under `spec/`
  - **Files:** Relevant `spec/` files as identified during implementation
  - **Verification:** Each significant decision from BRIEF.md has rationale captured in a spec file

- [ ] **TASK-03: Reconcile spec divergences**
  - **Goal:** Where implementation intentionally diverged from the planning brief, update the permanent specs under `spec/` to match reality
  - **Files:** Relevant `spec/` files
  - **Verification:** No contradictions between specs and implemented code

- [ ] **TASK-04: Add new vocabulary**
  - **Goal:** Add any terms coined during implementation to the relevant glossary files
  - **Files:** Relevant `spec/*/glossary.md` files
  - **Verification:** All new terms are defined in a glossary

- [ ] **TASK-05: Update spec index**
  - **Goal:** Ensure every `.md` file under `spec/` has an entry in `spec/README.md` with title and one-line description
  - **Files:** `spec/README.md`
  - **Verification:** `spec/README.md` entries match the actual files in `spec/`
