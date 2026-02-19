# Review Standards — Orchestration

> The orchestration process that all domain review skills follow.
> Each domain inherits this pattern and customises Step 2 (parallel dispatch) and may add domain-specific synthesis steps.

## Design context

The manifest-driven architecture replaced an earlier content-dumping approach where the orchestrator read the full diff or codebase into its own context, passed the entire content to all 16 agents, and collected all 16 outputs back in-context.
That design worked for small changesets (under 1500 lines) but hit context limits on every subagent when reviewing a moderate-sized mono-repo (~4000-line diff, ~60 files).

Three bottlenecks drove the redesign:

1. **Agent input saturation** — each agent received the full diff or codebase content (~60k+ tokens) in its task prompt, regardless of pillar relevance.
   Agents had Read, Grep, and Glob tools but were never instructed to use them for file discovery.
2. **Agent output accumulation** — each agent returned its findings as in-context text to the orchestrator.
   Sixteen agent outputs (5–15k tokens each) accumulated in the orchestrator's context alongside the original content.
3. **No selective filtering** — there was no mechanism to send only relevant files to each agent or to limit what the orchestrator held at any given time.

The target after redesign is 100k-line codebases — roughly 25x larger than what previously caused context exhaustion.
Each subsequent design decision (manifest input, file-based output, sequential synthesis) addresses one or more of these bottlenecks.

## Step 1: Scope identification

All domains use the same scoping algorithm.
The scope determines which files appear in the manifest (Step 2) and which review mode agents operate in.

- **No argument** — review all tracked files in the repository (full codebase).
  This is the default mode.
- **Path argument** — review files under that path.
- **PR number** — fetch the diff and review changed files only.
- **Dot (`.`)** — review changes from the main branch (`git diff main...HEAD`), changed files only.

Individual domains may add domain-specific scoping guidance (e.g., which file types to focus on).

### Why full codebase is the default (not diff)

The original default was diff-based review, but this limits agents to reviewing only changed files and misses systemic issues in the surrounding codebase.
Full-codebase review gives agents the complete picture — they can assess how a change fits into the broader architecture, identify pre-existing issues that interact with new code, and evaluate cross-cutting concerns (e.g., authentication patterns, observability gaps) that a diff alone would not surface.
Diff-based review remains available as an opt-in narrowing mode for focused change review (via dot or PR number arguments).
The manifest-driven architecture makes full-codebase review feasible at scale because agents self-select which files to read rather than receiving all content in-context.

### Unified flow

One code path handles both full-codebase and diff modes.
The manifest format adapts: full-codebase lists all tracked files with line counts; diff mode lists only changed files with change stats.
Agent review instructions work with both — agents read files via their tools and review what they find.

## Step 2: Manifest generation and parallel dispatch

### Manifest format

The orchestrator generates a lightweight file inventory — the **manifest** — and passes it to every agent in place of file content.
Agents use the manifest to decide which files to examine, then read those files themselves using their Read, Grep, and Glob tools.

The manifest fits in approximately 6k tokens for 500 files.

**Full-codebase manifest** (no argument, or path argument):

```
# Manifest: full-codebase
# Root: /absolute/path/to/repo
# Files: 342

src/api/auth.ts                         148
src/api/middleware/rate-limit.ts          63
src/api/routes/users.ts                 210
src/db/migrations/001_create_users.sql   34
...
```

Each line contains the file path and its line count, separated by whitespace.

**Diff manifest** (dot argument, or PR number):

```
# Manifest: diff (main...HEAD)
# Files changed: 12

src/api/auth.ts                         +32  -8
src/api/middleware/rate-limit.ts         +63  -0
src/api/routes/users.ts                 +15  -22
tests/api/auth.test.ts                  +44  -12
...
```

Each line contains the file path and its change stats (additions and deletions), separated by whitespace.

### Why manifest + self-select (not orchestrator pre-filtering)

Pre-filtering by the orchestrator (deciding which files each agent should review) would require domain knowledge in the orchestrator that belongs in the agents.
A security agent knows that a `Dockerfile` might expose secrets; an SRE agent knows that a `package.json` contains dependency information.
Self-selection keeps domain knowledge in the domain prompts and lets agents discover cross-cutting concerns the orchestrator would miss.

### Dispatch

Each domain defines its own dispatch table specifying:

- Which subagents to spawn (always 4, run in parallel)
- Which model each subagent uses (sonnet or haiku)
- Rationale for model selection

See each domain's `spec.md` Section 6 for the dispatch table.

Every agent receives:

1. The manifest (not file content)
2. Its pillar-specific review instructions (inlined at compile time)
3. Instructions to write raw findings to a file (see Step 3)

## Step 3: File-based agent output

Each agent writes its raw findings to a file rather than returning them as in-context text to the orchestrator.

**Output path:** `.donkey-review/<batch>/raw/<agent-name>.md`

### Why file-based output (not in-context return)

In-context return puts a hard ceiling on the combined output size of all agents.
File-based output decouples agent context from orchestrator context entirely.
The orchestrator can read files selectively and sequentially, never holding all 16 outputs simultaneously.

### Agent output contract

Each agent writes its findings in the standard finding format defined by its domain.
The orchestrator does not parse structured data — it reads the markdown findings and applies the synthesis algorithm.

## Step 4: Sequential domain synthesis

> **What lives in the compiled SKILL.md:** Only the synthesis algorithm (Steps 4 and 5) is compiled into each domain's `SKILL.md`.
> Scope detection (Step 1), manifest generation (Step 2), and dispatch are not written into the SKILL.md — the Claude Code skill model handles scope from the argument and knows which agents belong to the domain from the plugin registry.

The orchestrator reads one domain's raw output files at a time, synthesises the domain report, writes it to a file, then moves to the next domain.
This caps peak context to approximately 40k tokens of agent output per domain pass.

### Why sequential domain synthesis (not parallel)

Reading all 16 raw output files at once could still exhaust the orchestrator's context.
Sequential synthesis (4 files at a time per domain) caps peak consumption at approximately 40k tokens of agent output per domain pass.
The orchestrator writes each domain report to a file before moving to the next.

### Synthesis algorithm

All domains follow the same synthesis algorithm:

1. **Collect** — read the 4 raw output files for the domain from `.donkey-review/<batch>/raw/`
2. **Domain pre-filters** — apply domain-specific filters before deduplication (see each domain's spec for details):
   - **Security:** Remove findings with confidence below 50%. Every finding must include an exploit path.
   - **Data:** Restrict scope to data-related files (SQL, dbt, Spark, pipeline definitions, schema files, migration scripts). Apply consumer-first perspective.
   - **SRE, Architecture:** No domain-specific pre-filter. Proceed directly to deduplication.
3. **Deduplicate** — when two agents flag the same `file:line`, merge into one finding:
   - Take the **highest severity**
   - Take the **most restrictive maturity level** (HYG > L1 > L2 > L3)
   - Combine recommendations from both agents
   - Credit both subagents in the category column
4. **Aggregate maturity** — merge per-criterion assessments into one view:
   - All criteria met = `pass`
   - Mix of met and not met = `partial`
   - All criteria not met = `fail`
   - Previous level not passed = `locked`
5. **Prioritise** — HYG findings first, then by severity (HIGH > MEDIUM > LOW)

## Step 5: Output

Produce the maturity assessment report per the output format defined in `_base.md`.

## donkey-review:all — Flat Dispatch Across All Domains

The `/donkey-review:all` skill runs all 16 domain agents in parallel, producing four domain reports and one cross-domain summary.

### Why flat dispatch

Claude Code agents cannot spawn their own subagents (platform constraint).
A nested approach — skill spawns four domain orchestrators, each orchestrator spawns four agents — is therefore impossible.
Flat dispatch from the top-level skill is the only viable pattern.

### Dispatch table

All 16 agents are spawned simultaneously.
Each agent receives the manifest and writes its raw findings to `.donkey-review/<batch>/raw/<agent-name>.md`.

| Domain | Agent | Model |
|--------|-------|-------|
| SRE | `sre-response` | sonnet |
| SRE | `sre-observability` | sonnet |
| SRE | `sre-availability` | sonnet |
| SRE | `sre-delivery` | haiku |
| Security | `security-authn-authz` | sonnet |
| Security | `security-data-protection` | sonnet |
| Security | `security-input-validation` | sonnet |
| Security | `security-audit-resilience` | haiku |
| Architecture | `architecture-code` | sonnet |
| Architecture | `architecture-service` | sonnet |
| Architecture | `architecture-system` | sonnet |
| Architecture | `architecture-landscape` | sonnet |
| Data | `data-architecture` | sonnet |
| Data | `data-engineering` | sonnet |
| Data | `data-quality` | sonnet |
| Data | `data-governance` | sonnet |

### Model selection rationale

- **Sonnet** — used for pillars requiring nuanced judgement: subtle exploit pattern recognition, production-readiness assessment, design trade-off evaluation, data fitness assessment.
- **Haiku** — used for binary checklist pillars where a finding is either present or absent: SRE Delivery (backward-compatible or not), Security Audit/Resilience (audit logs present or not).

### Batch naming

Before dispatching agents, the skill assigns a unique batch name for the output directory.
Algorithm (applied in order of preference):

1. Git annotated tag on HEAD (e.g., `v1.2.0`)
2. `<branch-name>-<7-char-commit-hash>` (e.g., `feat/my-feature-a1b2c3d`)
3. `<YYYY-MM-DD>-<7-char-commit-hash>` (e.g., `2024-01-15-a1b2c3d`)

If the target directory already exists, append `-2`, `-3`, etc., until the name is unique.
Output directory: `.donkey-review/<batch-name>/`

### Output directory structure

```
.donkey-review/<batch-name>/
  raw/
    sre-response.md
    sre-observability.md
    sre-availability.md
    sre-delivery.md
    security-authn-authz.md
    security-data-protection.md
    security-input-validation.md
    security-audit-resilience.md
    architecture-code.md
    architecture-service.md
    architecture-system.md
    architecture-landscape.md
    data-architecture.md
    data-engineering.md
    data-quality.md
    data-governance.md
  sre.md
  security.md
  architecture.md
  data.md
  summary.md
```

### Per-domain synthesis

After all 16 agents have written their raw output files, the orchestrator synthesises one domain at a time, sequentially.

For each domain:

1. Read the domain's 4 raw output files from `.donkey-review/<batch-name>/raw/`
2. Apply the standard synthesis algorithm (collect, domain pre-filters, deduplicate, aggregate maturity, prioritise)
3. Write the domain report to `.donkey-review/<batch-name>/<domain>.md`
4. Move to the next domain

Each domain applies its own pre-filters where defined (Security confidence filter, Data scope filter).

Domain processing order: SRE, Security, Architecture, Data.

Output files written by the all skill:

- `.donkey-review/<batch-name>/sre.md`
- `.donkey-review/<batch-name>/security.md`
- `.donkey-review/<batch-name>/architecture.md`
- `.donkey-review/<batch-name>/data.md`

### Cross-domain summary

After all four domain reports are written, produce a cross-domain summary at `.donkey-review/<batch-name>/summary.md`.

The summary must contain:

- **Scope reviewed** — what was passed to agents (full codebase, path, diff, or PR) and the manifest statistics (file count, total lines or total changes)
- **Batch** — batch name and output directory path
- **Finding counts** — total count per domain and per severity level (HYG, HIGH, MEDIUM, LOW)
- **Cross-domain themes** — patterns appearing across two or more domains
- **Recommended next steps** — the three to five highest-priority actions across all domains
