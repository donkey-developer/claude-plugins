# Update agent review instructions for tool-based discovery

**Issue:** #66
**Branch:** feat/02-agent-tool-discovery
**Depends on:** #65
**Brief ref:** BRIEF.md — Solution

## Tasks

- [x] **TASK-01: Read current agent review instructions and shared prompts**
  - **Goal:** Understand how agents currently receive and process review input, so the update targets only the input/output handling and preserves analytical frameworks
  - **Brief ref:** BRIEF.md — Problem Statement
  - **Files:**
    - Read `plugins/donkey-review/prompts/shared/output-format.md`
    - Read `plugins/donkey-review/prompts/shared/constraints.md`
    - Read `plugins/donkey-review/prompts/sre/_base.md` (Review Instructions section)
    - Read `plugins/donkey-review/prompts/security/_base.md` (Review Instructions section)
    - Read `plugins/donkey-review/prompts/architecture/_base.md` (Review Instructions section)
    - Read `plugins/donkey-review/prompts/data/_base.md` (Review Instructions section)
    - Read `spec/review-standards/orchestration.md` (the updated spec from Issue 1)
  - **Verification:** You can describe how agents currently receive input, what their review instructions say, and what needs to change per the updated spec

- [x] **TASK-02: Add shared review-mode prompt for manifest-based file discovery**
  - **Goal:** Create or update a shared prompt file that instructs agents on how to handle manifest-based input: receive a file manifest, use Glob/Grep/Read to selectively examine files relevant to their pillar, and write findings to a specified output file path. This shared prompt will be included in all agents via the compile step
  - **Brief ref:** BRIEF.md — Solution (manifest-driven review, file-based output)
  - **Files:** `plugins/donkey-review/prompts/shared/review-mode.md` (new file, or update existing if a suitable shared prompt exists)
  - **Verification:**
    - The shared prompt defines how agents interpret a manifest (list of file paths + line counts or change stats)
    - The shared prompt instructs agents to use Read/Grep/Glob for selective file examination
    - The shared prompt instructs agents to write output to the file path provided by the orchestrator
    - The shared prompt works for both full-codebase and diff modes

- [ ] **TASK-03: Update domain `_base.md` Review Instructions sections**
  - **Goal:** Update the Review Instructions section in each domain's `_base.md` to reference the new review mode. Replace any language about reviewing "the changeset" or "the diff" with instructions to review files discovered via the manifest. Preserve all analytical framework instructions (STRIDE, ROAD, C4, data pillars) unchanged
  - **Brief ref:** BRIEF.md — Solution
  - **Files:**
    - `plugins/donkey-review/prompts/sre/_base.md`
    - `plugins/donkey-review/prompts/security/_base.md`
    - `plugins/donkey-review/prompts/architecture/_base.md`
    - `plugins/donkey-review/prompts/data/_base.md`
  - **Verification:**
    - Each `_base.md` Review Instructions section references manifest-based file discovery
    - No references to "the changeset" or "the diff" as the primary input remain
    - All analytical framework instructions are unchanged
    - All four domain `_base.md` files are consistent in their review mode instructions

- [ ] **TASK-04: Update compile script if needed and recompile**
  - **Goal:** If the new shared prompt file (`review-mode.md`) needs to be included in the compile pipeline, update `plugins/donkey-review/scripts/compile.sh`. Then recompile all agents and skills
  - **Brief ref:** BRIEF.md — Verification
  - **Files:**
    - `plugins/donkey-review/scripts/compile.sh` (if changes needed)
    - Run `./plugins/donkey-review/scripts/compile.sh`
  - **Verification:** `./plugins/donkey-review/scripts/compile.sh --check` exits 0

- [ ] **TASK-05: Final verification**
  - **Goal:** Confirm all agent prompts correctly instruct tool-based file discovery and file-based output
  - **Verification:**
    - All 16 compiled agents in `plugins/donkey-review/agents/` contain the new review mode instructions
    - No compiled agent references "the changeset" or "the diff" as primary input
    - All compiled agents instruct writing output to a file path
    - `./plugins/donkey-review/scripts/compile.sh --check` exits 0
