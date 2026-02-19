# Brief: Review Scalability

**Milestone:** Review Scalability (#4)
**GitHub:** https://github.com/donkey-developer/claude-plugins/milestone/4

## Context

The donkey-review plugin's `all` skill hit context limits on every single subagent when reviewing a moderate-sized mono-repo (~4000-line diff, ~60 files).
The root cause is architectural: the orchestrator reads the full diff/codebase into its own context, passes the entire content to all 16 agents, and collects all 16 outputs back in-context.

This design works for small changesets (<1500 lines) but fails at realistic scale.
The target is 100k-line codebases — roughly 25x larger than what currently breaks.

Additionally, the default review mode should be **full codebase** (not a diff).
Diff-based review should remain available as an opt-in narrowing mode.

## Problem Statement

Three bottlenecks cause context exhaustion:

1. **Agent input:** Each agent receives the full diff/codebase content (~60k+ tokens) in its task prompt, regardless of pillar relevance.
   Agents have Read, Grep, and Glob tools but are never told to use them for file discovery.
2. **Agent output:** Each agent returns its findings as in-context text to the orchestrator.
   16 agent outputs (5-15k tokens each) accumulate in the orchestrator's context alongside the original diff.
3. **No filtering:** There is no mechanism to send only relevant files to each agent or to limit what the orchestrator holds at any given time.

## Solution

### Manifest-driven review

Replace content-dumping with a manifest-driven architecture:

1. **Orchestrator generates a manifest** — a lightweight file inventory (paths and line counts) that fits in ~6k tokens for 500 files.
   For full-codebase mode: all tracked files.
   For diff mode: changed files with change stats.
2. **Agents receive the manifest and self-select** — each agent uses its existing Read, Grep, and Glob tools to examine files relevant to its pillar.
   Agents decide what to read based on file paths, extensions, and directory structure.
3. **Agents write output to files** — each agent writes its raw findings to `.donkey-review/<batch>/raw/<agent-name>.md` instead of returning them in the task result.
   The orchestrator reads these files for synthesis rather than collecting large in-context results.
4. **Orchestrator synthesises per domain sequentially** — reads one domain's 4 raw output files at a time, writes the domain report, then moves to the next domain.
   This caps peak context to ~40k tokens of agent output at a time.

### Unified flow

One code path handles both full-codebase and diff modes.
The manifest format adapts: full-codebase lists all tracked files; diff mode lists only changed files with change stats.
The agent review instructions work with both — agents read files and review what they find.

### Scope algorithm (new default)

1. **No argument** — review all tracked files in the repository (full codebase).
2. **Path argument** — review files under that path.
3. **PR number** — fetch the diff and review changed files only.
4. **Dot (`.`)** — review changes from the main branch (`git diff main...HEAD`), changed files only.

## Design Decisions

### Why manifest + self-select (not orchestrator pre-filtering)

Pre-filtering by the orchestrator (deciding which files each agent should review) would require domain knowledge in the orchestrator that belongs in the agents.
A security agent knows that a `Dockerfile` might expose secrets; an SRE agent knows that a `package.json` contains dependency information.
Self-selection keeps domain knowledge in the domain prompts and lets agents discover cross-cutting concerns the orchestrator would miss.

### Why file-based output (not in-context return)

In-context return puts a hard ceiling on the combined output size of all agents.
File-based output decouples agent context from orchestrator context entirely.
The orchestrator can read files selectively and sequentially, never holding all 16 outputs simultaneously.

### Why sequential domain synthesis (not parallel)

Reading all 16 raw output files at once could still exhaust the orchestrator's context.
Sequential synthesis (4 files at a time per domain) caps peak consumption at ~40k tokens of agent output per domain pass.
The orchestrator writes each domain report to a file before moving to the next.

## Scope

**In scope:**

- Updating orchestration spec with manifest-driven architecture
- Updating agent review instructions to use tool-based file discovery
- Updating agent output to file-based writes
- Updating all 5 skill files (all, sre, security, architecture, data)
- Recompiling all agents and skills

**Out of scope:**

- Changing agent analytical frameworks (STRIDE, ROAD, C4, etc.)
- Changing maturity criteria or severity scoring
- Changing the synthesis algorithm (dedup, aggregate, prioritise)
- Adding new agents or domains
- Performance optimisation beyond context-limit resolution

## Verification

- Run `/donkey-review:all` on a codebase with >3000 lines across >40 files — no agent hits context limits
- Run `/donkey-review:security` on the same codebase — domain skill also scales
- Run `/donkey-review:all .` (dot argument) — diff mode still works
- All domain reports and summary are produced correctly
- `./plugins/donkey-review/scripts/compile.sh --check` exits 0

## Issue Sequence

1. `01-spec-manifest-architecture.tasks.md` → Issue: "Spec: define manifest-driven review architecture" (no dependencies)
2. `02-agent-tool-discovery.tasks.md` → Issue: "Update agent review instructions for tool-based discovery" (depends on #1)
3. `03-skill-orchestration.tasks.md` → Issue: "Update skill orchestration for manifest-based dispatch" (depends on #2)
4. `04-close.tasks.md` → Issue: "Close milestone: Review Scalability" (depends on all above)
