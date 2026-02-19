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
