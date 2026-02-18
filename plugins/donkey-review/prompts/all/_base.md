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
