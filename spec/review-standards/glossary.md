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
| **Skill orchestrator** | The `/code-review:<domain>` skill that dispatches subagents, collects results, deduplicates, and synthesises the final report. |
| **Synthesis** | The process of merging 4 subagent reports into one consolidated maturity assessment. |
| **Deduplication** | When two subagents flag the same file:line, merging into one finding with the highest severity and most restrictive maturity tag. |

Note: Each domain uses its own structural term for the review dimension — "Zoom Level" (Architecture), "Pillar" (Security, SRE, Data). These are functionally equivalent: one subagent per dimension, dispatched in parallel.

## Output Terms

| Term | Definition |
|------|-----------|
| **Finding** | A single identified issue: severity, maturity level, category, file location, description, and recommendation. Domains may add fields (e.g., Security adds confidence and exploit scenario). |
| **Maturity assessment** | Per-criterion evaluation (met/not met/partially met) for each maturity level. |
| **Immediate action** | The single most important thing to fix. Hygiene failure if any exist, otherwise the top finding from the next achievable level. |
