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

## Dispatch — 16 Agents in Parallel

Spawn all 16 agents concurrently using the Task tool.
Do not wait for one agent before starting the next — all 16 run simultaneously.

Each agent receives:

1. The **manifest** (the full text generated in the Manifest Generation step)
2. An **output file path** where it must write its raw findings

The agent prompt for each task must include:

- The manifest text
- The instruction: "Write your findings to `.donkey-review/<batch-name>/raw/<agent-name>.md` using the Write tool."
- The instruction: "Use Read, Grep, and Glob tools to examine files from the manifest that are relevant to your pillar. Do not expect file content to be provided — you must read files yourself."

**SRE agents (model: sonnet except Delivery which uses haiku):**

| Agent | Model | Output file |
|-------|-------|-------------|
| `sre-response` | sonnet | `.donkey-review/<batch-name>/raw/sre-response.md` |
| `sre-observability` | sonnet | `.donkey-review/<batch-name>/raw/sre-observability.md` |
| `sre-availability` | sonnet | `.donkey-review/<batch-name>/raw/sre-availability.md` |
| `sre-delivery` | haiku | `.donkey-review/<batch-name>/raw/sre-delivery.md` |

**Security agents (model: sonnet except Audit/Resilience which uses haiku):**

| Agent | Model | Output file |
|-------|-------|-------------|
| `security-authn-authz` | sonnet | `.donkey-review/<batch-name>/raw/security-authn-authz.md` |
| `security-data-protection` | sonnet | `.donkey-review/<batch-name>/raw/security-data-protection.md` |
| `security-input-validation` | sonnet | `.donkey-review/<batch-name>/raw/security-input-validation.md` |
| `security-audit-resilience` | haiku | `.donkey-review/<batch-name>/raw/security-audit-resilience.md` |

**Architecture agents (all sonnet):**

| Agent | Model | Output file |
|-------|-------|-------------|
| `architecture-code` | sonnet | `.donkey-review/<batch-name>/raw/architecture-code.md` |
| `architecture-service` | sonnet | `.donkey-review/<batch-name>/raw/architecture-service.md` |
| `architecture-system` | sonnet | `.donkey-review/<batch-name>/raw/architecture-system.md` |
| `architecture-landscape` | sonnet | `.donkey-review/<batch-name>/raw/architecture-landscape.md` |

**Data agents (all sonnet):**

| Agent | Model | Output file |
|-------|-------|-------------|
| `data-architecture` | sonnet | `.donkey-review/<batch-name>/raw/data-architecture.md` |
| `data-engineering` | sonnet | `.donkey-review/<batch-name>/raw/data-engineering.md` |
| `data-quality` | sonnet | `.donkey-review/<batch-name>/raw/data-quality.md` |
| `data-governance` | sonnet | `.donkey-review/<batch-name>/raw/data-governance.md` |

Wait for all 16 agents to complete before proceeding to synthesis.

## Per-Domain Synthesis

Synthesise one domain at a time, sequentially.
This caps peak context to approximately 40k tokens of agent output per domain pass.

Domain processing order: SRE, Security, Architecture, Data.

For each domain:

1. **Read** the domain's 4 raw output files from `.donkey-review/<batch-name>/raw/`
2. **Apply** the synthesis algorithm below (collect, domain pre-filters, deduplicate, aggregate maturity, prioritise)
3. **Write** the domain report to `.donkey-review/<batch-name>/<domain>.md`
4. **Move** to the next domain

Do not read files from the next domain until the current domain's report has been written.

Output files:

- `.donkey-review/<batch-name>/sre.md`
- `.donkey-review/<batch-name>/security.md`
- `.donkey-review/<batch-name>/architecture.md`
- `.donkey-review/<batch-name>/data.md`

## Cross-Domain Summary

After all four domain reports are written, produce a cross-domain summary.

Read the four domain report files:

- `.donkey-review/<batch-name>/sre.md`
- `.donkey-review/<batch-name>/security.md`
- `.donkey-review/<batch-name>/architecture.md`
- `.donkey-review/<batch-name>/data.md`

Output file: `.donkey-review/<batch-name>/summary.md`

The summary must contain:

- **Scope reviewed** — what was passed to agents (full codebase, path, PR number, or diff description) and the manifest statistics (file count, total lines or total changes)
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
