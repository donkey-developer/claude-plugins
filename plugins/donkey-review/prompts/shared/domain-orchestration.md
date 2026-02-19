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
