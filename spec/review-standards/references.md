# Review Standards — References

> Project history, cross-domain design decisions, and references common to multiple domains. Each domain's `references.md` contains domain-specific framework origins, books, and standards.

## Maturity Model Origin

**Origin:** Original to this project.

**Design history:**
- PR #13/Issue #13: Initial maturity scoring concept -- hygiene factors vs aspirational targets
- PR #18: Added domain-specific maturity criteria to all 4 review domains
- PR #19: Rewrote as universal Hygiene gate (Irreversible/Total/Regulated) with outcome-based levels. Removed technique names from criteria.

**Key design decision (PR #19):** The Hygiene gate uses consequence-severity tests, not domain-specific checklists. This ensures the same escalation logic across Architecture, SRE, Security, and Data domains.

## Cross-Domain Project History

Key PRs that shaped the plugin across all domains:

| PR | What changed | Design impact |
|----|-------------|---------------|
| #18 | Cascading maturity model added | Domain-specific maturity criteria (HYG/L1/L2/L3) in `_base.md` and `SKILL.md` for all domains |
| #19 | Universal Hygiene gate, outcome-based levels | Removed technique names from criteria. Hygiene uses consequence-severity tests. All domain criteria rewritten as observable outcomes. |
| #21 | Batch orchestrator `/review-all` | All 4 domains run in parallel, each producing a sub-report |
| #23 | Namespace attempt (closed, not merged) | Skill namespacing via subdirectories didn't work as expected. Led to plugin-based distribution approach (`donkey-dev/`). |

## Cross-Domain Design Decisions

### Why outcome-based criteria (PR #19)

Technique names in criteria create false negatives. "Uses DDD" excludes teams that achieve bounded contexts through other means. "Implements OAuth 2.0" excludes teams using alternative authentication approaches. Outcome-based criteria are technology-neutral and verifiable from code.

### Why consequence-based Hygiene (PR #19)

Domain-specific hygiene checklists would produce inconsistent escalation logic. The three consequence-severity tests (Irreversible, Total, Regulated) apply uniformly to all domains -- the tests are about the nature of the damage, not the domain of the finding.

## Shared External References

### The Twelve-Factor App

**URL:** https://12factor.net/

Referenced by Architecture (Service zoom level deployability), Security (Factor III for secrets management, Factor XII for audit logging), and SRE (Factor III for config management, Factor IV for backing services, Factor XI for logs).
