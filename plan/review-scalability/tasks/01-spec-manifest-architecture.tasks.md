# Spec: define manifest-driven review architecture

**Issue:** #65
**Branch:** feat/01-spec-manifest-architecture
**Depends on:** none
**Brief ref:** BRIEF.md — Solution

## Tasks

- [x] **TASK-01: Read current orchestration spec and review framework**
  - **Goal:** Understand the current scope identification algorithm, dispatch pattern, and synthesis flow as defined in the specs, so the update preserves what works and replaces only what's broken
  - **Brief ref:** BRIEF.md — Problem Statement
  - **Files:**
    - Read `spec/review-standards/orchestration.md`
    - Read `spec/review-standards/review-framework.md`
  - **Verification:** You can describe the current scope algorithm, dispatch pattern, and the gap that causes context exhaustion

- [x] **TASK-02: Update orchestration spec with manifest-driven architecture**
  - **Goal:** Rewrite `spec/review-standards/orchestration.md` to define the new manifest-driven review architecture: new scope algorithm (whole-codebase default), manifest format specification, file-based agent output pattern, sequential domain synthesis, and unified flow for both full-codebase and diff modes
  - **Brief ref:** BRIEF.md — Solution (all subsections)
  - **Files:** `spec/review-standards/orchestration.md`
  - **Verification:**
    - Spec defines the new scope algorithm (no argument = full codebase, path = that path, PR# = diff, dot = diff from main)
    - Spec defines the manifest format (file paths + line counts for full-codebase; file paths + change stats for diff)
    - Spec defines file-based agent output to `.donkey-review/<batch>/raw/<agent-name>.md`
    - Spec defines sequential domain synthesis (read 4 files per domain, write domain report, move to next)
    - Spec preserves the existing synthesis algorithm (collect, pre-filter, dedup, aggregate, prioritise)

- [x] **TASK-03: Update review framework spec with new agent input/output pattern**
  - **Goal:** Update `spec/review-standards/review-framework.md` to reflect that agents receive a manifest (not content) and write output to files (not return in-context). Update the "No tool overhead in agents" rationale to explain why agents now actively use tools for file discovery
  - **Brief ref:** BRIEF.md — Design Decisions
  - **Files:** `spec/review-standards/review-framework.md`
  - **Verification:**
    - Framework spec describes agents as tool-driven reviewers that receive a manifest and self-select files
    - Framework spec describes file-based output pattern
    - Rationale for tool-based discovery is documented

- [x] **TASK-04: Final verification**
  - **Goal:** Confirm all spec updates are consistent and complete
  - **Verification:**
    - `spec/review-standards/orchestration.md` defines manifest format, scope algorithm, file-based output, sequential synthesis
    - `spec/review-standards/review-framework.md` reflects the new agent input/output pattern
    - No contradictions between the two spec files
    - `spec/README.md` entries are still accurate (update descriptions if needed)
