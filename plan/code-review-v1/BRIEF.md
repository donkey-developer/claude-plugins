# Code Review Plugin v1.0 — Planning Brief

## Purpose

Deliver the first plugin for the `donkey-developer/claude-plugins` marketplace: a code review plugin that extends generalist engineers' review capability across Architecture, Security, SRE, and Data Engineering.

## What This Delivers

- 5 slash commands: `/code-review:sre`, `/code-review:security`, `/code-review:architecture`, `/code-review:data`, `/code-review:all`
- 16 domain-specific subagents (4 domains x 4 pillars)
- A compilation pipeline that generates agents and skills from human-editable prompts
- Output reports written to `.code-review/<batch-name>/`

## Key Architecture Decisions

### 1. Three-tier file structure

```text
plugins/code-review/
├── skills/{domain}/SKILL.md      ← Orchestrators (user-triggered, dispatch + synthesise)
├── agents/{domain}-{pillar}.md   ← Self-contained subagents (16 total, inlined prompts)
└── prompts/                      ← Source of truth (human-editable, NOT read at runtime)
    ├── shared/                   ← Cross-domain content (including synthesis rules)
    └── {domain}/                 ← Domain + pillar content
```

### 2. Composition model

- **Agents are self-contained.** Each agent file inlines all context it needs (shared + domain base + pillar).
  Agents do NOT read external files at runtime.
- **Prompts are the source of truth.** The `prompts/` directory is human-editable source.
  Agent and skill files are "compiled" from prompts by `scripts/compile.sh`.
- **Skills compile synthesis rules from the same sources.** Both standalone domain reviews and `/code-review:all` produce identical domain reports.
- **Compilation is automated.** A pre-commit hook validates that generated files are in sync with their prompt sources.

### 3. code-review:all dispatches 16 agents flat

Subagents cannot spawn other subagents (Claude Code platform constraint).
Flat dispatch spawns all 16 agents in parallel, each in its own context window.
Only summarised results return to the parent, keeping context manageable.

### 4. Agent model allocation

| Domain | Pillar | Model | Rationale |
|--------|--------|-------|-----------|
| SRE | Response, Observability, Availability | sonnet | Nuanced judgement on production readiness |
| SRE | Delivery | haiku | Binary checklist (backward-compatible or not) |
| Security | AuthN/AuthZ, Data Protection, Input Validation | sonnet | Subtle exploit pattern recognition |
| Security | Audit & Resilience | haiku | Binary checklist (audit logs present or not) |
| Architecture | All 4 (Code, Service, System, Landscape) | sonnet | All levels require nuanced design judgement |
| Data | All 4 (Architecture, Engineering, Quality, Governance) | sonnet | Contextual assessment of data fitness |

### 5. Domain-specific synthesis rules

- **Security:** Confidence filter — remove findings below 50% before deduplication.
  Exploit path required for every finding.
- **Data:** Scope filter — focus on SQL, dbt, Spark, pipeline configs.
  Consumer-first perspective.
- **SRE, Architecture:** No domain-specific synthesis beyond shared algorithm.

### 6. Prompt size targets

- Shared content: ~180 lines total across 6 files
- Domain `_base.md`: ~200-250 lines each
- Pillar prompts: ~80-120 lines each
- **Total inlined per agent: ~460-550 lines (~3-4K tokens)** — well within context limits

## Issue Sequence

1. `01-scaffolding.tasks.md` → #18 "Create marketplace and plugin scaffolding" (no dependencies)
2. `02-shared-prompts.tasks.md` → #19 "Create shared cross-domain prompts" (depends on #18)
3. `03-sre-domain.tasks.md` → #20 "Create SRE domain review" (depends on #19, reference implementation)
4. `04-security-domain.tasks.md` → #21 "Create Security domain review" (depends on #19, parallel after SRE)
   `05-architecture-domain.tasks.md` → #22 "Create Architecture domain review" (depends on #19, parallel)
   `06-data-domain.tasks.md` → #23 "Create Data domain review" (depends on #19, parallel)
5. `07-code-review-all.tasks.md` → #24 "Create code-review:all orchestrator" (depends on #20-#23)
6. `08-close.tasks.md` → #25 "Close milestone: Code Review Plugin v1.0" (depends on all above)

## Sources

- **Implementation plan:** `Planner.md` — full plan (advisory; specs in `spec/` are authoritative)
- **Spike repo:** `https://github.com/LeeCampbell/code-review-llm` — cross-reference for tone and structure (advisory only; do not fetch at runtime)
- **Review framework:** `spec/review-standards/review-framework.md`
- **Design principles:** `spec/review-standards/design-principles.md`
- **Orchestration:** `spec/review-standards/orchestration.md`
- **Glossary:** `spec/review-standards/glossary.md`
- **SRE specs:** `spec/domains/sre/spec.md` (index to all SRE spec files)
- **Security specs:** `spec/domains/security/spec.md` (index to all Security spec files)
- **Architecture specs:** `spec/domains/architecture/spec.md` (index to all Architecture spec files)
- **Data specs:** `spec/domains/data/spec.md` (index to all Data spec files)
