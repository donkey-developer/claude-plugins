# Close milestone: Code Review Plugin v1.0

**Issue:** #25
**Branch:** feat/08-close
**Depends on:** #18, #19, #20, #21, #22, #23, #24
**Brief ref:** BRIEF.md (entire document — read as source material before updating specs)

## Tasks

- [x] **TASK-01: Update specs with new patterns**
  - **Goal:** Add any implementation patterns introduced during this milestone to the relevant spec files under `spec/`
  - **Details:** Review all PRs merged during this milestone. Identify patterns not yet captured in specs (e.g. compile pipeline pattern, three-tier file structure, flat dispatch strategy, prompt size targets).
  - **Verification:** Each new pattern has a section in the appropriate spec file

- [x] **TASK-02: Capture decision rationale**
  - **Goal:** Extract rationale from `BRIEF.md` and implementation experience — trade-offs considered, alternatives rejected, constraints that drove decisions — and add to the relevant spec files under `spec/`
  - **Details:** Key decisions to capture: flat dispatch vs nested dispatch, haiku vs sonnet model selection, compilation vs runtime file reads, confidence filter threshold, prompt size budgets.
  - **Verification:** Each significant decision from BRIEF.md has rationale captured in a spec file

- [ ] **TASK-03: Reconcile spec divergences**
  - **Goal:** Where implementation intentionally diverged from the planning brief, update the permanent specs under `spec/` to match reality
  - **Details:** Compare BRIEF.md and Planner.md against what was actually built. Update specs to reflect reality, not intent.
  - **Verification:** No contradictions between specs and implemented code

- [ ] **TASK-04: Add new vocabulary**
  - **Goal:** Add any terms coined during implementation to the relevant glossary files
  - **Details:** Check for new terms in: compile.conf, compile.sh, skill orchestrators, agent frontmatter, synthesis rules.
  - **Verification:** All new terms are defined in a glossary

- [ ] **TASK-05: Update spec index**
  - **Goal:** Ensure every `.md` file under `spec/` has an entry in `spec/README.md` with title and one-line description
  - **Verification:** `spec/README.md` entries match the actual files in `spec/`

- [ ] **TASK-06: Delete plan directory**
  - **Goal:** Remove `plan/code-review-v1/` — plans are transient, specs are permanent. Plans remain in git history.
  - **Verification:** `plan/code-review-v1/` does not exist

- [ ] **TASK-07: Delete Planner.md**
  - **Goal:** Remove `Planner.md` from the repo root — its content has been migrated to the BRIEF.md (now deleted) and permanent specs.
  - **Verification:** `Planner.md` does not exist at repo root

- [ ] **TASK-08: Close GitHub Milestone**
  - **Goal:** Verify all issues are closed, all PRs merged, then close the Milestone
  - **Verification:** GitHub Milestone shows as closed with 100% completion
