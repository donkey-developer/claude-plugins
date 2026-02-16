# Create code-review:all orchestrator

**Issue:** #24
**Branch:** feat/code-review-all
**Depends on:** #20, #21, #22, #23
**Brief ref:** BRIEF.md Section 3 (flat dispatch)

## Sources

- `Planner.md` — code-review:all dispatch strategy section
- `spec/review-standards/orchestration.md` — orchestration spec
- `plugins/code-review/prompts/shared/synthesis.md` — shared synthesis rules
- Each domain `_base.md` — domain-specific synthesis additions

## Tasks

- [ ] **TASK-01: Create all skill prompt source**
  - **Goal:** Create or update the prompt source content that the compile script uses to generate `skills/all/SKILL.md`
  - **Brief ref:** BRIEF.md Section 3 (flat dispatch of 16 agents)
  - **Files:**
    - Create/edit prompt source files as needed for the all-domain skill template
  - **Details:**
    - Scope detection (same algorithm as domain skills): path → use directly; PR# → `gh pr diff`; empty → `git diff` or prompt; "." → `git diff main...HEAD`
    - Batch naming: git tag > branch-shorthash > date-shorthash
    - Output dir: `mkdir -p .code-review/<batch-name>/`
    - Dispatch: spawn all 16 agents in parallel via Task tool, passing scope
    - Collect: gather results from all 16 agents
    - Per-domain synthesis: group by domain (4 groups of 4), apply `synthesis.md` + domain pre-filters, write domain report
    - Cross-domain summary: `.code-review/<batch-name>/summary.md`
    - Report: summary to user with finding counts and file paths
  - **Verification:** Prompt source exists with complete orchestration logic

- [ ] **TASK-02: Run compile.sh to generate skills/all/SKILL.md**
  - **Goal:** Generate the all-domain skill file from prompts
  - **Files generated:**
    - `plugins/code-review/skills/all/SKILL.md`
  - **Verification:**
    - `scripts/compile.sh` exits 0
    - `skills/all/SKILL.md` exists
    - Skill dispatches 16 agents (not 4 domain skills)
    - Per-domain synthesis includes domain-specific pre-filters (Security confidence, Data scope)
    - `scripts/compile.sh --check` exits 0

- [ ] **TASK-03: Verify all 16 agents and 5 skills are complete**
  - **Goal:** Full inventory check of all generated files
  - **Verification:**
    - 16 agent files exist in `agents/` with correct frontmatter
    - 5 skill files exist in `skills/` (sre, security, architecture, data, all)
    - All prompt source files exist (6 shared + 4 domains x 5 files = 26 total)
    - `compile.sh --check` exits 0 for all files
    - `plugin.json` correctly declares all 5 skills

- [ ] **TASK-04: Final verification**
  - **Goal:** Verify the complete code-review:all orchestrator works end-to-end
  - **Verification:**
    - `skills/all/SKILL.md` exists with flat dispatch of 16 agents
    - Synthesis rules are identical to standalone domain skills (compiled from same sources)
    - Output structure: `.code-review/<batch>/` with 4 domain reports + `summary.md`
    - Batch name collision handling (append `-2`, `-3` if directory exists)
