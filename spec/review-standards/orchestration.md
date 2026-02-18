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

## code-review:all — Flat Dispatch Across All Domains

The `/code-review:all` skill runs all 16 domain agents in parallel, producing four domain reports and one cross-domain summary.

### Why flat dispatch

Claude Code agents cannot spawn their own subagents (platform constraint).
A nested approach — skill spawns four domain orchestrators, each orchestrator spawns four agents — is therefore impossible.
Flat dispatch from the top-level skill is the only viable pattern.

### Dispatch table

All 16 agents are spawned simultaneously.
Only summarised results return to the parent skill, keeping the parent context window manageable.

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
Output directory: `.code-review/<batch-name>/`

### Per-domain synthesis

After collecting all 16 results, apply the standard synthesis algorithm (collect, deduplicate, aggregate maturity, prioritise) per domain.
Each domain also applies its own domain-specific synthesis steps (e.g., Security confidence filter).

Output files written by the all skill:

- `.code-review/<batch-name>/sre.md`
- `.code-review/<batch-name>/security.md`
- `.code-review/<batch-name>/architecture.md`
- `.code-review/<batch-name>/data.md`

### Cross-domain summary

After all four domain reports are written, produce a cross-domain summary at `.code-review/<batch-name>/summary.md`.

The summary must contain:

- **Scope reviewed** — what was passed to agents
- **Batch** — batch name and output directory path
- **Finding counts** — total count per domain and per severity level (HYG, HIGH, MEDIUM, LOW)
- **Cross-domain themes** — patterns appearing across two or more domains
- **Recommended next steps** — the three to five highest-priority actions across all domains
