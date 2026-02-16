# Code Review Plugin — Implementation Plan

## Context

We're building a Claude Code Plugin Marketplace for the `donkey-developer` GitHub org. The first plugin is `code-review`, providing domain-specific code reviews across Architecture, Security, SRE, and Data Engineering. The specs (39 files, ~6,600 lines) are complete; zero implementation exists. This plan covers the full v1.0 implementation.

The repo will be renamed from `code-review-plugin` to `claude-plugins` to reflect its role as a marketplace containing multiple plugins over time.

## Key Architecture Decisions

### Plugin model
- **Marketplace repo**: `donkey-developer/claude-plugins`
- **Plugin name**: `code-review` → commands are `/code-review:sre`, `/code-review:all`, etc.
- **Install flow**: `/plugin marketplace add donkey-developer/claude-plugins` then `/plugin install code-review@donkey-developer`

### Three-tier file structure (per `spec/review-standards/review-framework.md` lines 17-41)
```
plugins/code-review/
├── skills/{domain}/SKILL.md      ← Orchestrators (user-triggered, dispatch + synthesize)
├── agents/{domain}-{pillar}.md   ← Self-contained subagents (16 total, inlined prompts)
└── prompts/                      ← Source of truth (human-editable, NOT read at runtime)
    ├── shared/                   ← Cross-domain content
    └── {domain}/                 ← Domain + pillar content
```

### Composition model (per spec composition rules)
- **Agents are self-contained.** Each agent file inlines all context it needs (shared + domain base + pillar). Agents do NOT read external files at runtime.
- **Prompts are the source of truth.** The `prompts/` directory is human-editable source. Agent files are "compiled" from prompts.
- **Compilation for v1.0 is manual.** When a prompt changes, the corresponding agent file(s) must be updated. A build script can be added later.

### Skill naming (full domain names with code-review prefix)
- `skills/all/SKILL.md` → `/code-review:all`
- `skills/sre/SKILL.md` → `/code-review:sre`
- `skills/security/SKILL.md` → `/code-review:security`
- `skills/architecture/SKILL.md` → `/code-review:architecture`
- `skills/data/SKILL.md` → `/code-review:data`

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
│       └── prompts/                         ← Human-editable source (not read at runtime)
│           ├── shared/
│           │   ├── maturity-model.md        ← Hygiene gate, L1/L2/L3, status indicators
│           │   ├── severity-framework.md    ← HIGH/MEDIUM/LOW definitions
│           │   ├── design-principles.md     ← 5 core principles
│           │   ├── output-format.md         ← Finding table, maturity table, sections
│           │   └── constraints.md           ← Read-only, no cross-domain, no scores
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

### Phase 0: Scaffolding (1 issue, 1 PR)

| Issue | Title | Deliverables |
|-------|-------|-------------|
| #1 | Rename repo and create marketplace + plugin scaffolding | `marketplace.json`, `plugin.json`, directory structure, updated CLAUDE.md/README.md, `.gitignore` for `.code-review/` |

### Phase 1: Shared Prompts (1 issue, 1 PR)

| Issue | Title | Files |
|-------|-------|-------|
| #2 | Create shared cross-domain prompts | All 5 files in `prompts/shared/` |

Sources: `spec/review-standards/review-framework.md`, `spec/review-standards/design-principles.md`, `spec/review-standards/orchestration.md`

### Phase 2: SRE Domain — Reference Implementation (2 issues, 1 PR)

SRE is built first as the template for the other 3 domains.

| Issue | Title | Files |
|-------|-------|-------|
| #3 | Create SRE prompts (base + 4 pillars) | `prompts/sre/_base.md`, `prompts/sre/{response,observability,availability,delivery}.md` |
| #4 | Create SRE agents (4) and skill orchestrator | `agents/sre-{response,observability,availability,delivery}.md`, `skills/sre/SKILL.md` |

Sources: `spec/domains/sre/spec.md`, `spec/domains/sre/glossary.md`, `spec/domains/sre/framework-map.md`, `spec/domains/sre/maturity-criteria.md`, `spec/domains/sre/anti-patterns.md`, `spec/domains/sre/calibration.md`

Cross-check: `code-review-llm/.claude/prompts/sre/`, `code-review-llm/.claude/agents/sre-*.md`, `code-review-llm/.claude/skills/sre/SKILL.md`

### Phase 2: Security Domain (2 issues, 1 PR)

| Issue | Title | Files |
|-------|-------|-------|
| #5 | Create Security prompts (base + 4 pillars) | `prompts/security/_base.md`, `prompts/security/{authn-authz,data-protection,input-validation,audit-resilience}.md` |
| #6 | Create Security agents (4) and skill orchestrator | `agents/security-*.md`, `skills/security/SKILL.md` |

Domain-specific: confidence thresholds, exploit scenarios required, exclusion list, Tampering boundary rule.

### Phase 2: Architecture Domain (2 issues, 1 PR)

| Issue | Title | Files |
|-------|-------|-------|
| #7 | Create Architecture prompts (base + 4 zoom levels) | `prompts/architecture/_base.md`, `prompts/architecture/{code,service,system,landscape}.md` |
| #8 | Create Architecture agents (4) and skill orchestrator | `agents/architecture-*.md`, `skills/architecture/SKILL.md` |

Domain-specific: zoom-level scaling ("no findings" is valid for smaller projects), design-time focus.

### Phase 2: Data Domain (2 issues, 1 PR)

| Issue | Title | Files |
|-------|-------|-------|
| #9 | Create Data prompts (base + 4 pillars) | `prompts/data/_base.md`, `prompts/data/{architecture,engineering,quality,governance}.md` |
| #10 | Create Data agents (4) and skill orchestrator | `agents/data-*.md`, `skills/data/SKILL.md` |

Domain-specific: consumer-first perspective, L2 has 5 criteria (not 4), data-specific file scoping (SQL, dbt, Spark).

### Phase 3: Review-All Orchestrator (1 issue, 1 PR)

| Issue | Title | Files |
|-------|-------|-------|
| #11 | Create code-review:all orchestrator | `skills/all/SKILL.md` |

Implements: scope detection, batch naming, parallel dispatch of 4 domain skills, collection of sub-reports, summary.json + summary.md generation, completion output.

### Phase 4: Polish (2 issues, 1 PR)

| Issue | Title | Deliverables |
|-------|-------|-------------|
| #12 | Update documentation for v1.0 | README with install instructions, CLAUDE.md with new structure, CHANGELOG |
| #13 | Calibration pass against test codebase | Run all domains, verify output consistency, tune prompts |

## Implementation Sequence

```
Phase 0:  #1 Scaffolding
              │
Phase 1:  #2 Shared prompts
              │
Phase 2:  #3→#4 SRE (reference impl)
              │
          #5→#6 Security  ┐
          #7→#8 Architecture  ├── Can parallel after SRE establishes the pattern
          #9→#10 Data     ┘
              │
Phase 3:  #11 code-review:all (requires all 4 domain skills)
              │
Phase 4:  #12 Docs  +  #13 Calibration
```

**PR grouping** (8 PRs total):
1. `chore/marketplace-scaffolding` — Issue #1
2. `feat/shared-prompts` — Issue #2
3. `feat/sre-domain` — Issues #3-#4
4. `feat/security-domain` — Issues #5-#6
5. `feat/architecture-domain` — Issues #7-#8
6. `feat/data-domain` — Issues #9-#10
7. `feat/code-review-all` — Issue #11
8. `chore/v1-polish` — Issues #12-#13

## Key Implementation Details

### Skill orchestrator pattern (each domain SKILL.md)
1. **Scope detection**: path arg → use directly; PR number → `gh pr diff`; empty → `git diff` or interactive prompt; "." → `git diff main...HEAD`
2. **Batch naming**: git tag > branch-shorthash > date-shorthash
3. **Output dir**: `mkdir -p .code-review/<batch-name>/`
4. **Dispatch**: spawn 4 domain agents in parallel via Task tool, passing scope
5. **Synthesis**: collect → deduplicate (same file:line → merge, highest severity, most restrictive maturity) → aggregate maturity → prioritize (HYG > HIGH > MED > LOW)
6. **Write**: output to `.code-review/<batch-name>/{domain}.md`
7. **Report**: summary to user with finding counts and file path

### Agent template pattern (each agent .md file)
```markdown
---
name: {domain}-{pillar}
description: {one-line description}. Spawned by /code-review:{domain}.
model: sonnet
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
- Shared content: ~150 lines total across 5 files
- Domain `_base.md`: ~200-250 lines each
- Pillar prompts: ~80-120 lines each
- **Total inlined per agent: ~430-520 lines (~3-4K tokens)** — well within limits

## Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| code-review:all nesting depth (skill → 4 skills → 4 agents each) | May hit Claude Code limits | Test early in Phase 3; fallback: all.md dispatches 16 agents directly |
| Agent model selection (haiku for some agents) | Quality may be insufficient | Start with spec recommendations; upgrade to sonnet during calibration if needed |
| Prompt distillation quality | Missing critical patterns from specs | SRE as reference impl; cross-check against previous repo; calibration pass |
| Batch name collisions | Overwrites previous reports | Append `-2`, `-3` if directory exists |

## Verification

1. **Phase 0**: `claude plugin validate ./plugins/code-review` passes; `claude --plugin-dir ./plugins/code-review` loads; `/help` shows plugin
2. **Phase 2 (per domain)**: `/code-review:sre ./path/to/test/file` produces a valid report at `.code-review/<batch>/sre.md` with all required sections
3. **Phase 3**: `/code-review:all ./path/to/test/code` produces 4 sub-reports + summary.json + summary.md
4. **Phase 4**: Run against a real codebase; verify output format consistency across all domains; verify deduplication in code-review:all
