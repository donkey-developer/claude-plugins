# Code Review Plugin — Implementation Plan

## Context

We are building a Claude Code Plugin Marketplace for the `donkey-developer` GitHub org.
The first plugin is `code-review`, providing domain-specific code reviews across Architecture, Security, SRE, and Data Engineering.
The specs (39 files, ~6,600 lines) are complete; zero implementation exists.
This plan covers the full v1.0 implementation.

## Spike Repository

The spike repo at `https://github.com/LeeCampbell/code-review-llm` contains a prior implementation that originated this plugin idea.
That repo tried to do too many things, so the plugin work has been extracted to live here in `donkey-developer/claude-plugins`.

The spike repo structure under `.claude/` serves as a **cross-reference** for structure, tone, and content:

- `.claude/prompts/{domain}/_base.md` + `{pillar}.md` — prompt source files
- `.claude/agents/{domain}-{pillar}.md` — compiled agent files
- `.claude/skills/review-{domain}/SKILL.md` — skill orchestrators

**The specs in this repo are authoritative.**
Where the spike repo and the specs disagree, follow the specs.

## Key Architecture Decisions

### Plugin model

- **Marketplace repo**: `donkey-developer/claude-plugins`
- **Plugin name**: `code-review` → commands are `/code-review:sre`, `/code-review:all`, etc.
- **Install flow**: `/plugin marketplace add donkey-developer/claude-plugins` then `/plugin install code-review@donkey-developer`

### Three-tier file structure (per `spec/review-standards/review-framework.md` lines 17-41)

```
plugins/code-review/
├── skills/{domain}/SKILL.md      ← Orchestrators (user-triggered, dispatch + synthesise)
├── agents/{domain}-{pillar}.md   ← Self-contained subagents (16 total, inlined prompts)
└── prompts/                      ← Source of truth (human-editable, NOT read at runtime)
    ├── shared/                   ← Cross-domain content (including synthesis rules)
    └── {domain}/                 ← Domain + pillar content
```

### Composition model (per spec composition rules)

- **Agents are self-contained.** Each agent file inlines all context it needs (shared + domain base + pillar). Agents do NOT read external files at runtime.
- **Prompts are the source of truth.** The `prompts/` directory is human-editable source. Agent files are "compiled" from prompts.
- **Skills are compiled from prompts too.** Each SKILL.md inlines the shared synthesis rules from `prompts/shared/synthesis.md` plus any domain-specific synthesis additions from the domain's `_base.md`. This ensures standalone domain reviews and `/code-review:all` produce identical domain reports.
- **Compilation is automated.** A build script (`scripts/compile.sh`) generates all agent and skill files from prompts. Agent and skill files are NEVER hand-edited. A pre-commit hook validates that generated files are in sync with their prompt sources.

### Skill naming (full domain names with code-review prefix)

- `skills/all/SKILL.md` → `/code-review:all`
- `skills/sre/SKILL.md` → `/code-review:sre`
- `skills/security/SKILL.md` → `/code-review:security`
- `skills/architecture/SKILL.md` → `/code-review:architecture`
- `skills/data/SKILL.md` → `/code-review:data`

### Agent configuration

Each agent uses this frontmatter pattern:

```yaml
---
name: {domain}-{pillar}
description: {One-line description}. Spawned by /code-review:{domain} or /code-review:all.
model: {sonnet or haiku, per domain spec recommendation}
tools: Read, Grep, Glob
---
```

- **tools: Read, Grep, Glob** — agents are explicitly read-only per spec constraint "No auto-fix."
- **model** — follows each domain's spec recommendation:
  - SRE: sonnet for Response, Observability, Availability; haiku for Delivery
  - Security: sonnet for AuthN/AuthZ, Data Protection, Input Validation; haiku for Audit & Resilience
  - Architecture: sonnet for all 4 (Code, Service, System, Landscape)
  - Data: sonnet for all 4 (Architecture, Engineering, Quality, Governance)

### Skill orchestrator configuration

Each domain skill uses this frontmatter pattern:

```yaml
---
name: {domain}
description: {Domain name} code review across {list of pillars}.
argument-hint: [path|PR#|.]
allowed-tools: Task, Read, Grep, Glob, Bash, Write
---
```

- `Task` — to spawn pillar agents in parallel
- `Read, Grep, Glob` — for scope detection and file discovery
- `Bash` — for `git diff`, `gh pr diff`, `mkdir`
- `Write` — to write the output report

### Compilation pipeline

Agent files and skill files are generated from prompts by `scripts/compile.sh`.
This ensures prompts remain the single source of truth and prevents drift between prompts and their compiled outputs.

**What the compile script produces:**

- 16 agent files in `agents/` — each compiled from: shared prompts + domain `_base.md` + pillar prompt + review instructions
- 5 skill files in `skills/` — each compiled from: skill template + `synthesis.md` + domain synthesis additions

**Where agent metadata lives:**

- `prompts/compile.conf` — maps each agent to its model and one-line description
- Each domain's `_base.md` — contains a `## Review Instructions` section with the domain-specific attack/defence lens names (e.g., SEEMS/FaCTOR for SRE, STRIDE Threats/Security Properties for Security)

**Dependency graph** (derived from naming conventions):

- `agents/{domain}-{pillar}.md` depends on: `prompts/shared/*` + `prompts/{domain}/_base.md` + `prompts/{domain}/{pillar}.md` + `prompts/compile.conf`
- `skills/{domain}/SKILL.md` depends on: `prompts/shared/synthesis.md` + `prompts/{domain}/_base.md` + `prompts/compile.conf`
- `skills/all/SKILL.md` depends on: `prompts/shared/synthesis.md` + all domain `_base.md` files + `prompts/compile.conf`

**Pre-commit hook:**

- Runs `scripts/compile.sh` in check mode
- Compares generated output against committed agent/skill files
- Fails the commit if any file is out of sync, with a message to run `scripts/compile.sh`

**Workflow for changing a prompt:**

1. Edit the prompt file(s) in `prompts/`
2. Run `scripts/compile.sh`
3. Commit both the prompt changes and the regenerated agent/skill files
4. The pre-commit hook verifies consistency

### code-review:all dispatch strategy

The `:all` skill dispatches **16 agents directly** (flat dispatch), not 4 domain skills nested.

**Rationale:** Subagents cannot spawn other subagents (Claude Code platform constraint).
If `:all` invoked domain skills inline, they would run sequentially (one domain at a time), accumulating all intermediate results in the main conversation context.
With 16+ agents of review output, this risks context window exhaustion — especially as UX and Product domains are added later.

Flat dispatch spawns all 16 agents in parallel.
Each agent runs in its own context window.
Only summarised results return to the parent, keeping context manageable.

**Synthesis consistency:** Both standalone domain skills and `:all` compile their synthesis logic from the same source: `prompts/shared/synthesis.md` + domain-specific additions from each `_base.md`.
This ensures `/code-review:sre` and `/code-review:all` produce identical SRE domain reports.

The `:all` skill workflow:

1. Scope detection (same algorithm as domain skills)
2. Batch naming
3. Output dir: `mkdir -p .code-review/<batch-name>/`
4. Dispatch: spawn 16 agents in parallel via Task tool, passing scope
5. Collect: gather results from all 16 agents
6. Synthesise per domain: group by domain (4 groups of 4), apply `synthesis.md` rules + domain-specific pre-filters, write domain report
7. Write cross-domain summary: `.code-review/<batch-name>/summary.md`
8. Report: summary to user with finding counts and file paths

## Target Directory Structure

```
claude-plugins/                              ← Marketplace repo root
├── .claude-plugin/
│   └── marketplace.json                     ← Plugin catalogue
├── spec/                                    ← Source specs (NOT shipped with plugin)
│   ├── review-standards/                    ← Cross-domain framework
│   └── domains/{sre,security,architecture,data}/  ← Domain specs
├── plugins/
│   └── code-review/                         ← The plugin (what gets installed)
│       ├── .claude-plugin/
│       │   └── plugin.json
│       ├── skills/                          ← 5 orchestrator skills
│       │   ├── all/SKILL.md
│       │   ├── sre/SKILL.md
│       │   ├── security/SKILL.md
│       │   ├── architecture/SKILL.md
│       │   └── data/SKILL.md
│       ├── agents/                          ← 16 self-contained subagents
│       │   ├── sre-response.md
│       │   ├── sre-observability.md
│       │   ├── sre-availability.md
│       │   ├── sre-delivery.md
│       │   ├── security-authn-authz.md
│       │   ├── security-data-protection.md
│       │   ├── security-input-validation.md
│       │   ├── security-audit-resilience.md
│       │   ├── architecture-code.md
│       │   ├── architecture-service.md
│       │   ├── architecture-system.md
│       │   ├── architecture-landscape.md
│       │   ├── data-architecture.md
│       │   ├── data-engineering.md
│       │   ├── data-quality.md
│       │   └── data-governance.md
│       ├── scripts/
│       │   └── compile.sh                   ← Generates agents/ and skills/ from prompts/
│       └── prompts/                         ← Human-editable source (not read at runtime)
│           ├── compile.conf                 ← Agent metadata: name, model, description
│           ├── shared/
│           │   ├── maturity-model.md        ← Hygiene gate, L1/L2/L3, status indicators
│           │   ├── severity-framework.md    ← HIGH/MEDIUM/LOW definitions
│           │   ├── design-principles.md     ← 5 core principles
│           │   ├── output-format.md         ← Finding table, maturity table, sections
│           │   ├── constraints.md           ← Read-only, no cross-domain, no scores
│           │   └── synthesis.md             ← Dedup, aggregate maturity, prioritise
│           ├── sre/
│           │   ├── _base.md                 ← ROAD, SEEMS/FaCTOR, maturity criteria, glossary
│           │   ├── response.md              ← RP-01..RP-06 anti-patterns + checklist
│           │   ├── observability.md         ← OP-01..OP-07 anti-patterns + checklist
│           │   ├── availability.md          ← AP-01..AP-10 anti-patterns + checklist
│           │   └── delivery.md              ← DP-01..DP-09 anti-patterns + checklist
│           ├── security/
│           │   ├── _base.md                 ← STRIDE, threat/property duality, confidence thresholds
│           │   ├── authn-authz.md
│           │   ├── data-protection.md
│           │   ├── input-validation.md
│           │   └── audit-resilience.md
│           ├── architecture/
│           │   ├── _base.md                 ← C4 zoom levels, principles/erosion duality
│           │   ├── code.md
│           │   ├── service.md
│           │   ├── system.md
│           │   └── landscape.md
│           └── data/
│               ├── _base.md                 ← 4 Pillars, quality dimensions/decay patterns
│               ├── architecture.md
│               ├── engineering.md
│               ├── quality.md
│               └── governance.md
├── CLAUDE.md
└── README.md
```

## GitHub Milestone & Issues

### Milestone: "Code Review Plugin v1.0"

Each issue maps to exactly one PR (1 issue = 1 branch = 1 PR).

### Phase 0: Scaffolding (1 issue, 1 PR)

| Title | Branch | Deliverables |
|-------|--------|-------------|
| Create marketplace and plugin scaffolding | `chore/marketplace-scaffolding` | `marketplace.json`, `plugin.json`, directory structure, `scripts/compile.sh`, `prompts/compile.conf`, pre-commit hook, updated README.md, `.gitignore` for `.code-review/` |

### Phase 1: Shared Prompts (1 issue, 1 PR)

| Title | Branch | Files |
|-------|--------|-------|
| Create shared cross-domain prompts | `feat/shared-prompts` | All 6 files in `prompts/shared/` |

Sources: `spec/review-standards/review-framework.md`, `spec/review-standards/design-principles.md`, `spec/review-standards/orchestration.md`

### Phase 2: Domain Reviews (4 issues, 4 PRs)

SRE is the **reference implementation** — built first to establish the pattern for the other 3 domains.

| Title | Branch | Files |
|-------|--------|-------|
| Create SRE domain review | `feat/sre-domain` | `prompts/sre/_base.md` + 4 pillar prompts → `compile.sh` generates `agents/sre-*.md` (4) + `skills/sre/SKILL.md` |
| Create Security domain review | `feat/security-domain` | `prompts/security/_base.md` + 4 pillar prompts → `compile.sh` generates `agents/security-*.md` (4) + `skills/security/SKILL.md` |
| Create Architecture domain review | `feat/architecture-domain` | `prompts/architecture/_base.md` + 4 pillar prompts → `compile.sh` generates `agents/architecture-*.md` (4) + `skills/architecture/SKILL.md` |
| Create Data domain review | `feat/data-domain` | `prompts/data/_base.md` + 4 pillar prompts → `compile.sh` generates `agents/data-*.md` (4) + `skills/data/SKILL.md` |

**Domain sources** (same pattern for each domain, substitute `{domain}`):

- `spec/domains/{domain}/spec.md` — domain specification index
- `spec/domains/{domain}/anti-patterns.md` — anti-patterns with code examples
- `spec/domains/{domain}/maturity-criteria.md` — domain-specific maturity criteria
- `spec/domains/{domain}/framework-map.md` — framework mapping
- `spec/domains/{domain}/glossary.md` — domain-specific terms
- `spec/domains/{domain}/calibration.md` — calibration guidance

**Cross-reference** (same pattern for each domain, substitute `{domain}` and `{pillar}`):

- `https://github.com/LeeCampbell/code-review-llm` → `.claude/prompts/{domain}/_base.md` + `.claude/prompts/{domain}/{pillar}.md`
- `https://github.com/LeeCampbell/code-review-llm` → `.claude/agents/{domain}-{pillar}.md`
- `https://github.com/LeeCampbell/code-review-llm` → `.claude/skills/review-{domain}/SKILL.md`

**Domain-specific notes:**

- **SRE:** ROAD framework, SEEMS/FaCTOR duality. No special synthesis rules beyond the common algorithm.
- **Security:** STRIDE framework, threat/property duality. Confidence thresholds (remove findings below 50% confidence before deduplication). Exploit scenarios required for each finding. Explicit exclusion list (dependency scanning, secret scanning handled by dedicated tools). Tampering boundary rule (must be within code boundary, not infrastructure).
- **Architecture:** C4 zoom levels, principles/erosion duality. Zoom-level scaling — "no findings" is valid for smaller projects at higher zoom levels. Design-time focus (evaluates decisions, not just implementation). Do NOT prescribe specific patterns by name.
- **Data:** 4 Pillars, quality dimensions/decay patterns duality. Consumer-first perspective. L2 has 5 criteria (not 4). Data-specific file scoping (SQL, dbt, Spark, pipeline configs). Do NOT prescribe specific modelling approaches.

### Phase 3: Review-All Orchestrator (1 issue, 1 PR)

| Title | Branch | Files |
|-------|--------|-------|
| Create code-review:all orchestrator | `feat/code-review-all` | `skills/all/SKILL.md` |

Dispatches 16 agents directly (flat, parallel).
Per-domain synthesis compiled from `prompts/shared/synthesis.md` + domain `_base.md` additions.
Produces 4 domain reports + `summary.md`.

### Phase 4: Close-out (1 issue, 1 PR)

| Title | Branch | Deliverables |
|-------|--------|-------------|
| Close milestone: Code Review Plugin v1.0 | `chore/close-code-review-v1` | Update specs with new patterns, capture decision rationale, reconcile divergences, update docs (README, CLAUDE.md), update spec index, delete plan directory, close GitHub Milestone |

## Implementation Sequence

```
Phase 0:  Scaffolding
              │
Phase 1:  Shared prompts
              │
Phase 2:  SRE domain (reference implementation)
              │
          Security domain    ┐
          Architecture domain ├── Follow the SRE pattern; can parallel after SRE
          Data domain        ┘
              │
Phase 3:  code-review:all (requires all 4 domain skills)
              │
Phase 4:  Close milestone
```

**8 issues, 8 PRs, 8 branches:**

1. `chore/marketplace-scaffolding` — Scaffolding
2. `feat/shared-prompts` — Shared prompts
3. `feat/sre-domain` — SRE domain
4. `feat/security-domain` — Security domain
5. `feat/architecture-domain` — Architecture domain
6. `feat/data-domain` — Data domain
7. `feat/code-review-all` — code-review:all
8. `chore/close-code-review-v1` — Close milestone

## Key Implementation Details

### Skill orchestrator pattern (each domain SKILL.md)

1. **Scope detection**: path arg → use directly; PR number → `gh pr diff`; empty → `git diff` or interactive prompt; "." → `git diff main...HEAD`
2. **Batch naming**: git tag > branch-shorthash > date-shorthash
3. **Output dir**: `mkdir -p .code-review/<batch-name>/`
4. **Dispatch**: spawn 4 domain agents in parallel via Task tool, passing scope
5. **Synthesis** (compiled from `prompts/shared/synthesis.md` + domain `_base.md`): collect → apply domain pre-filters (if any) → deduplicate (same file:line → merge, highest severity, most restrictive maturity) → aggregate maturity → prioritise (HYG > HIGH > MED > LOW)
6. **Write**: output to `.code-review/<batch-name>/{domain}.md`
7. **Report**: summary to user with finding counts and file path

### Agent template pattern (generated by `compile.sh`)

```markdown
---
name: {domain}-{pillar}
description: {One-line description}. Spawned by /code-review:{domain} or /code-review:all.
model: {sonnet or haiku — see Agent configuration section}
tools: Read, Grep, Glob
---

{Inlined shared content: maturity model, severity, design principles, output format, constraints}

{Inlined domain _base: purpose, framework, duality, maturity criteria, glossary}

{Inlined pillar prompt: focus areas, anti-patterns with code examples, checklist}

## Review Instructions

1. Examine code in scope
2. Apply {attack lens} to identify issues
3. Apply {defence lens} to verify protections
4. Assess each finding against maturity criteria and hygiene gate
5. Include "What's Good" section
6. Output in standard format
```

### Prompt size targets (to stay within agent context budgets)

- Shared content: ~180 lines total across 6 files
- Domain `_base.md`: ~200–250 lines each
- Pillar prompts: ~80–120 lines each
- **Total inlined per agent: ~460–550 lines (~3–4K tokens)** — well within limits

## Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Agent model selection (haiku for some agents) | Quality may be insufficient | Start with spec recommendations; upgrade to sonnet if quality is lacking |
| Prompt distillation quality | Missing critical patterns from specs | SRE as reference implementation; cross-check against spike repo |
| Batch name collisions | Overwrites previous reports | Append `-2`, `-3` if directory exists |
| Plugin caching affects path resolution | Agents can not read prompts/ at runtime | This is by design — agents inline all content via compile.sh. No runtime file reads. |
| 16 parallel agents in code-review:all | May hit Claude Code concurrency limits | Monitor during Phase 3; can batch into 4 waves of 4 if needed |
| Prompt/agent drift | Agent files diverge from prompt sources after hand-edits | Prevented by compile.sh + pre-commit hook. Agents are never hand-edited. |

## Verification

1. **Phase 0**: `claude plugin validate ./plugins/code-review` passes; `claude --plugin-dir ./plugins/code-review` loads; `scripts/compile.sh` runs without error; pre-commit hook rejects a commit with a stale agent file
2. **Phase 2 (per domain)**: `scripts/compile.sh` generates agents and skill from prompts; `/code-review:sre ./path/to/test/file` produces a valid report at `.code-review/<batch>/sre.md` with all required sections
3. **Phase 3**: `/code-review:all ./path/to/test/code` produces 4 domain reports + `summary.md` in `.code-review/<batch>/`
