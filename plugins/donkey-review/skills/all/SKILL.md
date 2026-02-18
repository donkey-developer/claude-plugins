---
name: all
description: Comprehensive code review across all domains — dispatches 16 agents in parallel.
argument-hint: [path|PR#|.]
allowed-tools: Task, Read, Grep, Glob, Bash, Write
---

## Scope Identification

Determine what to review before dispatching agents.

Apply the following algorithm in order:

1. **File or directory argument** — if the user provides a path, use it directly as the review scope.
2. **PR number** — if the argument is a numeric string, fetch the diff with `gh pr diff <number>`.
3. **Dot (`.`)** — review all changes from the main branch: `git diff main...HEAD`.
4. **Empty argument** — run `git diff` to review unstaged and staged changes; if the diff is empty, prompt the user to specify a scope.

Pass the resolved scope (file path or diff output) to every agent in the dispatch step.

## Batch Naming

Assign a unique batch name for the output directory before dispatching agents.
Apply the following algorithm in order of preference:

1. **Git tag** — if the HEAD commit has an annotated tag, use it (e.g., `v1.2.0`).
2. **Branch and short hash** — use `<branch-name>-<7-char-commit-hash>` (e.g., `feat/my-feature-a1b2c3d`).
3. **Date and short hash** — use `<YYYY-MM-DD>-<7-char-commit-hash>` (e.g., `2024-01-15-a1b2c3d`).

**Collision handling:** if `.donkey-review/<batch-name>/` already exists, append `-2`, `-3`, etc., until the name is unique.

Create the output directory: `mkdir -p .donkey-review/<batch-name>/`

## Dispatch — 16 Agents in Parallel

Spawn all 16 agents concurrently using the Task tool.
Pass the resolved scope to each agent.
Do not wait for one agent before starting the next — all 16 run simultaneously.

**SRE agents (model: sonnet except Delivery which uses haiku):**

| Agent | Model |
|-------|-------|
| `sre-response` | sonnet |
| `sre-observability` | sonnet |
| `sre-availability` | sonnet |
| `sre-delivery` | haiku |

**Security agents (model: sonnet except Audit/Resilience which uses haiku):**

| Agent | Model |
|-------|-------|
| `security-authn-authz` | sonnet |
| `security-data-protection` | sonnet |
| `security-input-validation` | sonnet |
| `security-audit-resilience` | haiku |

**Architecture agents (all sonnet):**

| Agent | Model |
|-------|-------|
| `architecture-code` | sonnet |
| `architecture-service` | sonnet |
| `architecture-system` | sonnet |
| `architecture-landscape` | sonnet |

**Data agents (all sonnet):**

| Agent | Model |
|-------|-------|
| `data-architecture` | sonnet |
| `data-engineering` | sonnet |
| `data-quality` | sonnet |
| `data-governance` | sonnet |

Collect all 16 results before proceeding to synthesis.

## Per-Domain Synthesis

Group findings by domain (SRE, Security, Architecture, Data).
For each domain, apply the synthesis algorithm below and write a domain report.

Output files:

- `.donkey-review/<batch-name>/sre.md`
- `.donkey-review/<batch-name>/security.md`
- `.donkey-review/<batch-name>/architecture.md`
- `.donkey-review/<batch-name>/data.md`

## Cross-Domain Summary

After all four domain reports are written, produce a cross-domain summary.

Output file: `.donkey-review/<batch-name>/summary.md`

The summary must contain:

- **Scope reviewed** — what was passed to agents (path, PR number, or diff description)
- **Batch** — the batch name and output directory path
- **Finding counts** — total count per domain and per severity level (HYG, HIGH, MEDIUM, LOW)
- **Cross-domain themes** — patterns that appear across two or more domains (e.g., a missing abstraction flagged by both Architecture and SRE)
- **Recommended next steps** — the three to five highest-priority actions across all domains

## Report to User

After writing all files, report to the user:

```
Batch: <batch-name>
Output: .donkey-review/<batch-name>/

Domain reports:
  SRE:          .donkey-review/<batch-name>/sre.md          (<N> findings)
  Security:     .donkey-review/<batch-name>/security.md     (<N> findings)
  Architecture: .donkey-review/<batch-name>/architecture.md (<N> findings)
  Data:         .donkey-review/<batch-name>/data.md         (<N> findings)

Summary: .donkey-review/<batch-name>/summary.md
```

## Synthesis Algorithm

Combine findings from all pillar subagents into a single domain report.

### Step 1: Collect

Gather all findings from every subagent. Preserve the original severity, maturity level, category, and recommendation.

### Step 2: Domain Pre-filters

Apply domain-specific filters before deduplication:

- **Security:** Remove findings with confidence below 50%. Every finding must include an exploit path.
- **Data:** Restrict scope to SQL, dbt, Spark, and pipeline configuration files. Apply consumer-first perspective.
- **SRE, Architecture:** No domain-specific pre-filter. Proceed directly to deduplication.

### Step 3: Deduplicate

When two or more agents flag the same `file:line`, merge into one finding:

- Take the **highest severity** (HYG > HIGH > MEDIUM > LOW)
- Take the **most restrictive maturity level** (HYG > L1 > L2 > L3)
- Combine recommendations from all contributing agents
- Credit all contributing subagents in the Category column

### Step 4: Aggregate Maturity

Merge per-criterion assessments from all subagents into one maturity table:
- All criteria met at a level = `pass`
- Mix of met and not met = `partial`
- All criteria not met or critical criteria missing = `fail`
- Previous level not passed = `locked`

### Step 5: Prioritise

Order the final findings list:

1. `HYG` findings first
2. Then by severity: `HIGH` > `MEDIUM` > `LOW`
3. Within the same severity, order by file path

## Synthesis Pre-filter

**Apply before deduplication.**

Remove any finding with confidence below 50% (LOW confidence).
These are theoretical concerns that add noise without value.

After removing LOW confidence findings, continue with the shared synthesis algorithm: deduplicate, aggregate, and prioritise.

Domain-specific synthesis rule: the confidence filter runs **before** deduplication.
A finding removed by the confidence filter does not appear in the synthesised output, even if multiple pillars raised the same low-confidence concern.

## Synthesis

### Data Pre-filter

Before deduplication, apply the following domain-specific filters:

**Scope filter:** Focus analysis on data-related files — SQL files, Python/Spark data processing scripts, dbt models, pipeline definitions, schema files, and migration scripts.
Non-data files (application code, UI components, configuration unrelated to data) should receive lower analytical weight; flag findings only where data handling is directly implicated.

**Consumer-first perspective:** For every finding, ask "How will downstream consumers experience this?"
A schema change that the producer considers minor may be a breaking change for consumers.
Prioritise findings that affect data consumers over findings that only affect internal implementation.
