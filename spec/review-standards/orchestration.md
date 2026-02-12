# Review Standards — Orchestration

> The orchestration process that all domain review skills follow. Each domain inherits this pattern and customises Step 2 (parallel dispatch) and may add domain-specific synthesis steps.

## Step 1: Scope identification

All domains use the same scoping algorithm:

- File or directory argument: review that path
- Empty or ".": review recent changes (`git diff`) or prompt for scope
- PR number: fetch the diff

Individual domains may add domain-specific scoping guidance (e.g., which file types to focus on).

## Step 2: Parallel dispatch

Each domain defines its own dispatch table specifying:
- Which subagents to spawn (always 4, run in parallel)
- Which model each subagent uses (sonnet or haiku)
- Rationale for model selection

See each domain's `spec.md` Section 6 for the dispatch table.

## Step 3: Synthesis

All domains follow the same synthesis algorithm:

1. **Collect** findings from all 4 subagents
2. **Deduplicate** — when two agents flag the same `file:line`, merge into one finding:
   - Take the **highest severity**
   - Take the **most restrictive maturity level** (HYG > L1 > L2 > L3)
   - Combine recommendations from both agents
   - Credit both subagents in the category column
3. **Aggregate maturity** — merge per-criterion assessments into one view:
   - All criteria met = `pass`
   - Mix of met and not met = `partial`
   - All criteria not met = `fail`
   - Previous level not passed = `locked`
4. **Prioritise** — HYG findings first, then by severity (HIGH > MEDIUM > LOW)

Individual domains may add domain-specific synthesis steps (e.g., Security applies a confidence filter between Step 1 and Step 2 of synthesis).

## Step 4: Output

Produce the maturity assessment report per the output format defined in `_base.md`.
