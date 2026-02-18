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
code-review/
  agents/
    <domain>-<subagent>.md     # Subagent: one per review dimension (16 total)
  prompts/
    compile.conf               # Agent and skill registry (name, model, description)
    shared/                    # Cross-domain content inlined into every agent
    <domain>/
      _base.md                 # Domain context: framework, maturity criteria, synthesis rules
      <subagent>.md            # Pillar checklist
    all/
      _base.md                 # code-review:all orchestration instructions only
  scripts/
    compile.sh                 # Generates agents/ and skills/ from prompts/
  skills/
    <domain>/SKILL.md          # Domain orchestrator: dispatch 4 agents, synthesise, write report
    all/SKILL.md               # Cross-domain orchestrator: dispatch 16 agents, write 5 reports
```

### Composition rules

1. **Each agent file is self-contained.** It embeds the full content of `_base.md` + its subagent prompt. Agents do not reference external files at runtime — all context must be inlined.
2. **Prompts are the source of truth.** The `prompts/<domain>/` directory contains the human-readable, LLM-agnostic checklists. Agent files are compiled from these.
3. **Domain SKILL.md files contain only the synthesis algorithm.** Scope detection and agent dispatch are handled by the Claude Code skill runtime. The `all/SKILL.md` is the exception: it contains full orchestration instructions (scope detection, batch naming, dispatch table, synthesis, and cross-domain summary) because the 16-agent cross-domain review requires explicit guidance.

### When modifying files

| Change type | Files to update |
|-------------|-----------------|
| Add/change a pillar checklist item | `prompts/<domain>/<subagent>.md` then recompile the corresponding `agents/<domain>-<subagent>.md` |
| Change shared context (severity, maturity, output format) | `prompts/shared/<file>.md` then recompile ALL agent files |
| Change domain context (framework, maturity criteria) | `prompts/<domain>/_base.md` then recompile all agents for that domain |
| Change domain synthesis rules | `prompts/<domain>/_base.md` (the `## Synthesis` section) then recompile `skills/<domain>/SKILL.md` and `skills/all/SKILL.md` |
| Change `code-review:all` orchestration logic | `prompts/all/_base.md` then recompile `skills/all/SKILL.md` |
| Add a new domain skill | Add to `compile.conf`, create `prompts/<domain>/`, recompile |
| Add a new subagent | New prompt file, new `compile.conf` entry, recompile to generate agent file, update `skills/<domain>/SKILL.md` |

## Compilation Pipeline

Agent and skill files are generated from source prompts by `scripts/compile.sh`.
The compilation process is automated — never edit generated files by hand.

### compile.conf

`prompts/compile.conf` is the single registry of all agents and skills.
Each entry declares the type, name, model, and description:

```
type|name|model|description
agent|sre-response|sonnet|SRE Response pillar review — ...
skill|all|sonnet|Comprehensive code review across all domains — ...
```

The `compile.sh` script reads this file to know which files to generate.

### How compilation works

**Agent files** (`agents/<domain>-<pillar>.md`) are assembled from:

1. YAML frontmatter — name, description, model, tools — derived from `compile.conf`
2. All shared prompt files from `prompts/shared/` (alphabetical, excluding `synthesis.md`)
3. The domain base file: `prompts/<domain>/_base.md`
4. The pillar prompt file: `prompts/<domain>/<pillar>.md`

**Skill files** (`skills/<domain>/SKILL.md`) are assembled from:

- For domain skills: `prompts/shared/synthesis.md` + the `## Synthesis` section extracted from `prompts/<domain>/_base.md`
- For the `all` skill: `prompts/all/_base.md` + `prompts/shared/synthesis.md` + the `## Synthesis` section from every domain's `_base.md`

### Prompt size targets

These targets keep inlined agent context manageable:

| Source | Target size |
|--------|-------------|
| Shared content (all 6 files combined) | ~180 lines |
| Domain `_base.md` | ~200–250 lines |
| Pillar prompt | ~80–120 lines |
| **Total inlined per agent** | **~460–550 lines (~3–4 K tokens)** |

### Why compile rather than read at runtime

Compilation was chosen over having agents read prompt files at runtime for two reasons:

1. **Startup cost.** Each agent spawned by the skill occupies its own context window.
   Having every agent read 5–6 shared files before starting its review adds latency for each of 4–16 parallel agents.
   Inlining eliminates this cost.

2. **No tool overhead in agents.** Agents are read-only reviewers (Read, Grep, Glob tools only).
   Removing the need to read their own prompt files keeps agent context focused on the codebase being reviewed.

The trade-off is that generated files become stale if prompts change without recompiling.
The pre-commit hook and `--check` mode address this.

### Checking compiled files

Run `./scripts/compile.sh --check` to verify generated files are in sync with their sources.
A pre-commit hook runs this check automatically; commits are blocked if any generated file is stale.

To regenerate all files: `./scripts/compile.sh`

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

- **No auto-fix.** The review is read-only. Agents have Read, Grep, Glob tools only — no Bash, no Write, no Edit.
- **No cross-domain findings.** Each domain reviews only its own concerns. Architecture does not flag SRE issues, Security does not flag Data issues, etc.
- **No numeric scores.** Status is pass/partial/fail/locked. No percentages, no weighted scores.
- **No prescribing specific tools.** Never recommend a specific library, framework, or vendor. Describe the outcome, let the team choose the implementation.
