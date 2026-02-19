# Update skill orchestration for manifest-based dispatch

**Issue:** #67
**Branch:** feat/03-skill-orchestration
**Depends on:** #66
**Brief ref:** BRIEF.md — Solution

## Tasks

- [x] **TASK-01: Read current skill files and updated spec**
  - **Goal:** Understand the current skill orchestration logic and the target architecture from the updated spec, so the skill rewrite preserves synthesis algorithms and output formats while replacing scope identification and dispatch
  - **Brief ref:** BRIEF.md — Solution
  - **Files:**
    - Read `plugins/donkey-review/skills/all/SKILL.md`
    - Read `plugins/donkey-review/skills/sre/SKILL.md`
    - Read `plugins/donkey-review/skills/security/SKILL.md`
    - Read `plugins/donkey-review/skills/architecture/SKILL.md`
    - Read `plugins/donkey-review/skills/data/SKILL.md`
    - Read `spec/review-standards/orchestration.md` (the updated spec from Issue 1)
  - **Verification:** You can describe the current skill orchestration flow and the specific changes required per the updated spec

- [ ] **TASK-02: Rewrite `all` skill with manifest-based orchestration**
  - **Goal:** Rewrite `plugins/donkey-review/skills/all/SKILL.md` to implement the manifest-driven architecture: (1) new scope algorithm with whole-codebase default, (2) manifest generation (file paths + line counts or change stats), (3) dispatch agents with manifest + output file path instead of content, (4) sequential domain synthesis reading from raw output files, (5) cross-domain summary reading from domain report files. Preserve batch naming, synthesis algorithm, and output format unchanged
  - **Brief ref:** BRIEF.md — Solution (all subsections)
  - **Files:** `plugins/donkey-review/skills/all/SKILL.md`
  - **Verification:**
    - Scope section implements: no argument = full codebase, path = that path, PR# = diff, dot = diff from main
    - Dispatch section passes manifest and output file path to each agent, not content
    - Synthesis section reads `.donkey-review/<batch>/raw/<agent>.md` files per domain sequentially
    - Batch naming and cross-domain summary are preserved
    - The skill instructs agents to write output to `.donkey-review/<batch>/raw/<agent-name>.md`

- [ ] **TASK-03: Update domain skill files with manifest-based dispatch**
  - **Goal:** Update the four domain skill files (`sre`, `security`, `architecture`, `data`) to use the same manifest-based dispatch pattern as the `all` skill. Domain skills dispatch 4 agents each. Apply the same scope algorithm, manifest generation, and file-based output/synthesis pattern. If domain skills currently lack scope identification (relying on the Claude Code runtime), add it per the updated spec
  - **Brief ref:** BRIEF.md — Solution
  - **Files:**
    - `plugins/donkey-review/skills/sre/SKILL.md`
    - `plugins/donkey-review/skills/security/SKILL.md`
    - `plugins/donkey-review/skills/architecture/SKILL.md`
    - `plugins/donkey-review/skills/data/SKILL.md`
  - **Verification:**
    - Each domain skill has the new scope algorithm (whole-codebase default)
    - Each domain skill generates a manifest and passes it to agents with an output file path
    - Each domain skill reads raw output files for synthesis
    - Synthesis algorithms per domain are preserved

- [ ] **TASK-04: Recompile all skills**
  - **Goal:** Recompile all skills so compiled output reflects the updated skill source files
  - **Brief ref:** BRIEF.md — Verification
  - **Files:** Run `./plugins/donkey-review/scripts/compile.sh`
  - **Verification:** `./plugins/donkey-review/scripts/compile.sh --check` exits 0

- [ ] **TASK-05: Final verification**
  - **Goal:** Confirm all skill files correctly implement manifest-based orchestration
  - **Verification:**
    - `plugins/donkey-review/skills/all/SKILL.md` implements full manifest-driven flow
    - All 4 domain skill files implement manifest-driven dispatch
    - All compiled skills under `plugins/donkey-review/skills/*/` are in sync
    - `./plugins/donkey-review/scripts/compile.sh --check` exits 0
