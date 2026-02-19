# Review Standards — Glossary

> Terminology used across all review domains. Each domain inherits these definitions and adds domain-specific terms in its own glossary.

## Maturity Model Terms

| Term | Definition |
|------|-----------|
| **Hygiene Gate** | A promotion gate that overrides maturity levels. Any finding is promoted to `HYG` if it passes any of three consequence-severity tests: Irreversible, Total, or Regulated. |
| **L1 (Foundations)** | The basics are in place. Each domain defines what "basics" means in its context. |
| **L2 (Hardening)** | Production-ready practices. Each domain defines what "hardening" means in its context. |
| **L3 (Excellence)** | Best-in-class. Each domain defines what "excellence" means in its context. |
| **HIGH severity** | Must fix before merge. Each domain defines impact in its own terms (structural, exploitation, production, data). |
| **MEDIUM severity** | May require follow-up ticket. |
| **LOW severity** | Nice to have. |
| **pass** | All criteria at this level are met. |
| **partial** | Some criteria met, some not. |
| **fail** | No criteria met, or critical criteria missing. |
| **locked** | Previous level not achieved; this level cannot be assessed. |

## Orchestration Terms

| Term | Definition |
|------|-----------|
| **Subagent** | A specialised reviewer that analyses code against one dimension's checklist. Runs in parallel with the other subagents. Each domain uses 4 subagents. |
| **Skill orchestrator** | The `/donkey-review:<domain>` skill that dispatches subagents, collects results, deduplicates, and synthesises the final report. |
| **Synthesis** | The process of merging 4 subagent reports into one consolidated maturity assessment. |
| **Deduplication** | When two subagents flag the same file:line, merging into one finding with the highest severity and most restrictive maturity tag. |
| **Flat dispatch** | The pattern used by `/donkey-review:all` to spawn all 16 agents directly from the skill, rather than nesting through domain orchestrators. Required because subagents cannot spawn their own subagents (platform constraint). |
| **Content-dumping** | The original architecture (replaced by manifest-driven review) where the orchestrator read the full diff or codebase into its own context, passed the entire content to all agents, and collected all outputs back in-context. Failed at moderate scale (~4000-line diff, ~60 files). |
| **Diff mode** | Review mode that examines only changed files. Activated by passing a dot (`.`) argument for `git diff main...HEAD` or a PR number. The manifest lists changed files with addition/deletion stats. Contrast with full-codebase mode. |
| **Full-codebase mode** | The default review mode. Reviews all tracked files in the repository (or under a specified path). The manifest lists every file with its line count. Contrast with diff mode. |
| **Manifest** | A lightweight file inventory (paths and line counts or change stats) that agents receive in place of file content. Fits approximately 6k tokens for 500 files. Full-codebase manifests list all tracked files with line counts; diff manifests list changed files with addition/deletion stats. |
| **Scope identification** | Step 1 of the orchestration flow. Determines which files appear in the manifest based on the user's argument: no argument (full codebase), path (subtree), PR number (diff), or dot (diff from main). |
| **Self-selection** | The pattern where agents decide which files to examine based on the manifest, using their domain knowledge and Read/Grep/Glob tools. Keeps domain knowledge in the domain prompts rather than requiring the orchestrator to pre-filter files per agent. |
| **Sequential synthesis** | Reading one domain's raw output files at a time, synthesising that domain's report, and writing it to file before moving to the next domain. Caps peak context to approximately 40k tokens of agent output per domain pass. |
| **Tool-driven discovery** | Design principle (#6) where agents discover and read files themselves using Read, Grep, and Glob tools rather than receiving file content in their task prompt. Replaces content-dumping to remove the hard ceiling on reviewable codebase size. |
| **Unified flow** | One code path handling both full-codebase and diff modes. The manifest format adapts (line counts vs change stats) but the agent review instructions and synthesis algorithm remain the same. |
| **Batch** | A single review run. Each batch has a unique name derived from the git context (annotated tag, branch+hash, or date+hash) and produces output in `.donkey-review/<batch-name>/`. |
| **Batch name** | The unique identifier for a batch's output directory. Algorithm: annotated git tag > `<branch>-<7-char-hash>` > `<YYYY-MM-DD>-<7-char-hash>`. Collisions resolved by appending `-2`, `-3`, etc. |

Note: Each domain uses its own structural term for the review dimension — "Zoom Level" (Architecture), "Pillar" (Security, SRE, Data). These are functionally equivalent: one subagent per dimension, dispatched in parallel.

## Compilation Terms

| Term | Definition |
|------|-----------|
| **compile.conf** | The registry file (`prompts/compile.conf`) that declares every agent and skill: type, name, model, and one-line description. `compile.sh` reads this to know what to generate. |
| **compile.sh** | The build script (`scripts/compile.sh`) that generates all agent and skill files from prompt sources. Run after editing any prompt file. Supports `--check` mode to verify compiled files are in sync. |
| **Pre-commit hook** | A git hook that runs `compile.sh --check` before every commit. Blocks commits where any generated file is out of sync with its prompt sources, enforcing that agents and prompts never diverge. |

## Output Terms

| Term | Definition |
|------|-----------|
| **Cross-domain attribution** | A parenthetical reference to a sibling domain within a finding (e.g., "(also flagged by Security)" or "Architecture (cross-domain)"). Prohibited by the universal constraints because it undermines domain independence. |
| **Domain pre-filter** | A domain-specific filter applied during synthesis before deduplication. Examples: Security's confidence filter, Data's scope filter. Domains without pre-filters proceed directly to deduplication. |
| **Finding** | A single identified issue: severity, maturity level, category, file location, description, and recommendation. Domains may add fields (e.g., Security adds confidence and exploit scenario). |
| **Fix direction** | The recommendation text within a finding that describes what should change. Must describe the required outcome, not name specific tools, libraries, or vendors. |
| **Immediate action** | The single most important thing to fix. Hygiene failure if any exist, otherwise the top finding from the next achievable level. |
| **Maturity assessment** | Per-criterion evaluation (met/not met/partially met) for each maturity level. |
| **Positive observation** | A "What's Good" entry identifying an operational or design pattern worth preserving, grounded in specific file references and code evidence. Generic praise without file references is prohibited. |
| **Raw findings file** | A markdown file written by a single agent at `.donkey-review/<batch>/raw/<agent-name>.md` containing unprocessed findings before deduplication and synthesis. |
