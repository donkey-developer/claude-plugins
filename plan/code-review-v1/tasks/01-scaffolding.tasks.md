# Create marketplace and plugin scaffolding

**Issue:** #18
**Branch:** chore/marketplace-scaffolding
**Depends on:** none
**Brief ref:** BRIEF.md Sections 1-2

## Tasks

- [x] **TASK-01: Create marketplace catalogue**
  - **Goal:** Create the marketplace directory and catalogue file that registers available plugins
  - **Brief ref:** BRIEF.md Section 1 (three-tier file structure)
  - **Files:**
    - Create `.claude-plugin/marketplace.json`
  - **Spec ref:** `Planner.md` — Plugin model section
  - **Verification:** File exists with valid JSON containing `code-review` plugin entry

- [ ] **TASK-02: Create plugin manifest and directory structure**
  - **Goal:** Create the plugin root, manifest, and all subdirectories
  - **Brief ref:** BRIEF.md Section 1 (three-tier file structure)
  - **Files:**
    - Create `plugins/code-review/.claude-plugin/plugin.json`
    - Create directories: `plugins/code-review/skills/`, `plugins/code-review/agents/`, `plugins/code-review/prompts/shared/`, `plugins/code-review/prompts/sre/`, `plugins/code-review/prompts/security/`, `plugins/code-review/prompts/architecture/`, `plugins/code-review/prompts/data/`, `plugins/code-review/scripts/`
    - Create directories: `plugins/code-review/skills/all/`, `plugins/code-review/skills/sre/`, `plugins/code-review/skills/security/`, `plugins/code-review/skills/architecture/`, `plugins/code-review/skills/data/`
  - **Verification:** `plugin.json` exists with valid JSON; all directories exist

- [ ] **TASK-03: Create compile.conf**
  - **Goal:** Create the agent metadata configuration file that maps each agent to its model and description
  - **Brief ref:** BRIEF.md Section 4 (agent model allocation)
  - **Files:**
    - Create `plugins/code-review/prompts/compile.conf`
  - **Spec ref:** `Planner.md` — Compilation pipeline section, Agent configuration section
  - **Details:** 16 agent entries, each with: name, model (sonnet/haiku per BRIEF.md Section 4), one-line description. Also 5 skill entries for domain orchestrators.
  - **Verification:** File contains 16 agent entries and 5 skill entries with correct model assignments

- [ ] **TASK-04: Create compile.sh**
  - **Goal:** Create the build script that generates agent and skill files from prompt sources
  - **Brief ref:** BRIEF.md Section 2 (composition model)
  - **Files:**
    - Create `plugins/code-review/scripts/compile.sh`
  - **Spec ref:** `Planner.md` — Compilation pipeline section
  - **Details:**
    - Reads `compile.conf` for agent metadata
    - For each agent: concatenates shared prompts + domain `_base.md` + pillar prompt + review instructions → writes `agents/{domain}-{pillar}.md` with YAML frontmatter
    - For each domain skill: concatenates skill template + `synthesis.md` + domain synthesis additions → writes `skills/{domain}/SKILL.md`
    - For all skill: concatenates skill template + `synthesis.md` + all domain synthesis additions → writes `skills/all/SKILL.md`
    - Supports `--check` mode that compares output to existing files and exits non-zero if out of sync
    - Must be idempotent — running twice produces identical output
  - **Verification:** Script runs without error (exits 0); `--check` mode works; script is executable

- [ ] **TASK-05: Create pre-commit hook**
  - **Goal:** Create a git pre-commit hook that validates compiled files are in sync with prompts
  - **Brief ref:** BRIEF.md Section 2 (composition model)
  - **Files:**
    - Create `.githooks/pre-commit` (or configure in existing hooks directory)
  - **Details:** Runs `scripts/compile.sh --check` and fails the commit with a message to run `scripts/compile.sh` if files are out of sync
  - **Verification:** Hook is executable; `git config core.hooksPath` points to hooks directory

- [ ] **TASK-06: Update .gitignore**
  - **Goal:** Ensure `.code-review/` output directories are ignored by git
  - **Files:**
    - Edit `.gitignore` (create if needed)
  - **Verification:** `.code-review/` is listed in `.gitignore`

- [ ] **TASK-07: Update root README.md**
  - **Goal:** Update the repository README to describe the marketplace and code-review plugin
  - **Files:**
    - Edit `README.md`
  - **Verification:** README describes the marketplace concept and the code-review plugin

- [ ] **TASK-08: Final verification**
  - **Goal:** Verify all scaffolding deliverables are in place
  - **Verification:**
    - `.claude-plugin/marketplace.json` exists and is valid JSON
    - `plugins/code-review/.claude-plugin/plugin.json` exists and is valid JSON
    - `plugins/code-review/prompts/compile.conf` has 16 agent entries and 5 skill entries
    - `plugins/code-review/scripts/compile.sh` is executable and runs without error
    - Pre-commit hook is installed and executable
    - `.gitignore` includes `.code-review/`
    - Directory structure matches BRIEF.md Section 1
