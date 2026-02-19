---
name: security
description: Security code review across AuthN/AuthZ, Data Protection, Input Validation, and Audit/Resilience.
argument-hint: [path|PR#|.]
allowed-tools: Task, Read, Grep, Glob, Bash, Write
---

## Scope Identification

Determine what to review before generating the manifest.

Apply the following algorithm in order:

1. **No argument** — review all tracked files in the repository (full codebase). This is the default.
2. **Path argument** — if the user provides a file or directory path, review files under that path.
3. **PR number** — if the argument is a numeric string, fetch the diff and review changed files only.
4. **Dot (`.`)** — review changes from the main branch (`git diff main...HEAD`), changed files only.

The scope determines whether a full-codebase manifest or a diff manifest is generated.

## Manifest Generation

After determining scope, generate a **manifest** — a lightweight file inventory.
The orchestrator passes the manifest to agents, not file content.
Agents use the manifest to decide which files to examine, then read those files themselves using their Read, Grep, and Glob tools.

### Full-codebase manifest

Used when no argument is provided, or when a path argument is provided.

Run `git ls-files` to list all tracked files (or filter to the given path).
For each file, count lines with `wc -l`.

Format the manifest as follows:

```
# Manifest: full-codebase
# Root: /absolute/path/to/repo
# Files: <total file count>

src/api/auth.ts                         148
src/api/middleware/rate-limit.ts          63
src/api/routes/users.ts                 210
src/db/migrations/001_create_users.sql   34
...
```

Each line contains the file path and its line count, separated by whitespace.

### Diff manifest

Used when the argument is a dot (`.`) or a PR number.

For a dot argument, run `git diff --numstat main...HEAD`.
For a PR number, run `gh pr diff <number> --patch` and parse the stats, or use `git diff --numstat` against the PR's base.

Format the manifest as follows:

```
# Manifest: diff (main...HEAD)
# Files changed: <count>

src/api/auth.ts                         +32  -8
src/api/middleware/rate-limit.ts         +63  -0
src/api/routes/users.ts                 +15  -22
tests/api/auth.test.ts                  +44  -12
...
```

Each line contains the file path and its change stats (additions and deletions), separated by whitespace.

## Batch Naming

Assign a unique batch name for the output directory before dispatching agents.
Apply the following algorithm in order of preference:

1. **Git tag** — if the HEAD commit has an annotated tag, use it (e.g., `v1.2.0`).
2. **Branch and short hash** — use `<branch-name>-<7-char-commit-hash>` (e.g., `feat/my-feature-a1b2c3d`).
3. **Date and short hash** — use `<YYYY-MM-DD>-<7-char-commit-hash>` (e.g., `2024-01-15-a1b2c3d`).

**Collision handling:** if `.donkey-review/<batch-name>/` already exists, append `-2`, `-3`, etc., until the name is unique.

Create the output directory structure:

```
mkdir -p .donkey-review/<batch-name>/raw/
```

## Dispatch — 4 Agents in Parallel

Spawn all 4 Security agents concurrently using the Task tool.
Do not wait for one agent before starting the next — all 4 run simultaneously.

Each agent receives:

1. The **manifest** (the full text generated in the Manifest Generation step)
2. An **output file path** where it must write its raw findings

The agent prompt for each task must include:

- The manifest text
- The instruction: "Write your findings to `.donkey-review/<batch-name>/raw/<agent-name>.md` using the Write tool."
- The instruction: "Use Read, Grep, and Glob tools to examine files from the manifest that are relevant to your pillar. Do not expect file content to be provided — you must read files yourself."

| Agent | Model | Output file |
|-------|-------|-------------|
| `security-authn-authz` | sonnet | `.donkey-review/<batch-name>/raw/security-authn-authz.md` |
| `security-data-protection` | sonnet | `.donkey-review/<batch-name>/raw/security-data-protection.md` |
| `security-input-validation` | sonnet | `.donkey-review/<batch-name>/raw/security-input-validation.md` |
| `security-audit-resilience` | haiku | `.donkey-review/<batch-name>/raw/security-audit-resilience.md` |

Wait for all 4 agents to complete before proceeding to synthesis.

## Synthesis

Read the 4 raw output files from `.donkey-review/<batch-name>/raw/` and synthesise into a single Security domain report.

Output file: `.donkey-review/<batch-name>/security.md`

## Report to User

After writing the domain report, report to the user:

```
Batch: <batch-name>
Output: .donkey-review/<batch-name>/

Security report: .donkey-review/<batch-name>/security.md (<N> findings)
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
