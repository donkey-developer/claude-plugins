# Review Standards — Framework

> Definitions for audience, maturity model, severity framework, and universal constraints. All domain specifications inherit this framework and add domain-specific extensions.

## Audience

| Who | Uses the spec for |
|-----|-------------------|
| **Autonomous coding agents** | Building/modifying prompt files, agent definitions, skill orchestrators |
| **Human prompt engineers** | Reviewing agent output, calibrating severity, refining checklists |
| **Plugin consumers** | Understanding what the review evaluates and why |

## Plugin File Layout

Each review domain manifests as files within the plugin following the same structure. See [Plugin Structure](https://code.claude.com/docs/en/plugins-reference) for file layout conventions.

```
donkey-dev/
  agents/
    <domain>-<subagent>.md     # Subagent: one per review dimension
  prompts/<domain>/
    _base.md                   # Shared context: frameworks, maturity model, output format
    <subagent>.md              # Subagent checklist
  skills/
    review-<domain>/SKILL.md   # Orchestrator: scope, parallel dispatch, synthesis, output
```

### Composition rules

1. **Each agent file is self-contained.** It embeds the full content of `_base.md` + its subagent prompt. Agents do not reference external files at runtime -- all context must be inlined.
2. **Prompts are the source of truth.** The `prompts/<domain>/` directory contains the human-readable, LLM-agnostic checklists. Agent files are compiled from these.
3. **The skill orchestrator dispatches and synthesises.** It does not contain review logic -- that lives in the agents.

### When modifying files

| Change type | Files to update |
|-------------|-----------------|
| Add/change a checklist item | `prompts/<domain>/<subagent>.md` then recompile the corresponding `agents/<domain>-<subagent>.md` |
| Change shared context (severity, maturity, output format) | `prompts/<domain>/_base.md` then recompile ALL agent files for that domain |
| Change orchestration logic | `skills/review-<domain>/SKILL.md` only |
| Add a new subagent | New prompt file, new agent file, update SKILL.md to spawn additional agent |

## Maturity Model

### Hygiene Gate

A promotion gate that overrides maturity levels. Any finding at any level is promoted to `HYG` if it passes any of these three consequence-severity tests:

| Test | Question |
|------|----------|
| **Irreversible** | If this goes wrong, can the damage be undone? |
| **Total** | Can this take down the entire service or cascade beyond its boundary? |
| **Regulated** | Does this violate a legal or compliance obligation? |

Any "yes" to any test = `HYG`. The Hygiene flag trumps all maturity levels.

Each domain provides its own examples for these tests in its glossary.

### Maturity Levels

Levels are cumulative. Each requires the previous. Each domain's `maturity-criteria.md` provides detailed criteria with thresholds.

| Level | Name | One-line description |
|-------|------|---------------------|
| **L1** | Foundations | The basics are in place. |
| **L2** | Hardening | Production-ready practices. |
| **L3** | Excellence | Best-in-class. |

Each domain provides its own one-line description that contextualises these levels.

### Status Indicators

Used in maturity assessment tables:

| Indicator | Meaning |
|-----------|---------|
| `pass` | All criteria at this level are met |
| `partial` | Some criteria met, some not |
| `fail` | No criteria met, or critical criteria missing |
| `locked` | Previous level not achieved; this level cannot be assessed |

## Severity Framework

All domains use the same three-level severity structure. Each domain defines its own impact framing.

| Level | Merge decision |
|-------|----------------|
| **HIGH** | Must fix before merge |
| **MEDIUM** | May require follow-up ticket |
| **LOW** | Nice to have |

Severity measures consequence, not implementation difficulty.

## Universal Constraints

These constraints apply to all review domains:

- **No auto-fix.** The review is read-only. Agents have Read, Grep, Glob tools only -- no Bash, no Write, no Edit.
- **No cross-domain findings.** Each domain reviews only its own concerns. Architecture does not flag SRE issues, Security does not flag Data issues, etc.
- **No numeric scores.** Status is pass/partial/fail/locked. No percentages, no weighted scores.
- **No prescribing specific tools.** Never recommend a specific library, framework, or vendor. Describe the outcome, let the team choose the implementation.
