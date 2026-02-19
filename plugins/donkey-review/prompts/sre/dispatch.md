## Dispatch — 4 Agents in Parallel

Spawn all 4 SRE agents concurrently using the Task tool.
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
| `sre-response` | sonnet | `.donkey-review/<batch-name>/raw/sre-response.md` |
| `sre-observability` | sonnet | `.donkey-review/<batch-name>/raw/sre-observability.md` |
| `sre-availability` | sonnet | `.donkey-review/<batch-name>/raw/sre-availability.md` |
| `sre-delivery` | haiku | `.donkey-review/<batch-name>/raw/sre-delivery.md` |

Wait for all 4 agents to complete before proceeding to synthesis.

## Synthesis

Read the 4 raw output files from `.donkey-review/<batch-name>/raw/` and synthesise into a single SRE domain report.

Output file: `.donkey-review/<batch-name>/sre.md`

## Report to User

After writing the domain report, report to the user:

```
Batch: <batch-name>
Output: .donkey-review/<batch-name>/

SRE report: .donkey-review/<batch-name>/sre.md (<N> findings)
```
