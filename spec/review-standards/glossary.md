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
