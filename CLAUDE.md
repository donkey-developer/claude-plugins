# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A Code Review Plugin for Claude Code that enables generalist software engineers to extend their review capability across Architecture, Security, Site Reliability Engineering (SRE), and Data Engineering disciplines. The plugin provides slash commands (`review-all`, `review-sec`, `review-sre`, `review-arch`, `review-data`) that perform domain-specific code reviews with progressive level reporting.

## Work Hierarchy

All non-trivial work is organised in three levels:

```
Milestone          → The deliverable (what stakeholders care about)
  └── Issue        → A phase of work producing a reviewable, mergeable unit (1 Issue = 1 PR)
        └── Task   → An atomic unit a stateless agent can complete in one turn
```

**Example:**

```
Milestone: "Code-Review Plugin v1"
├── Issue #1: Create SRE code review        → PR: feat/sre-domain → closes #1
│   ├── TASK-01: Create SRE base prompt
│   ├── TASK-02: Create SRE Response agent
│   └── ...
├── Issue #2: Create Security code review   → PR: feat/sec-domain → closes #2
├── Issue #3: Create Architecture code review
├── Issue #4: Create Data code review
└── Issue #5: Create comprehensive review   → PR: feat/review-all → closes #5
```

### File structure for plans

```
plan/{milestone-name}/
├── SPEC.md                         ← Milestone-level: the what and why
└── tasks/
    ├── 01-{issue-name}.tasks.md    ← Task list for Issue #1
    ├── 02-{issue-name}.tasks.md    ← Task list for Issue #2
    └── ...                         ← One file per Issue
```

Each task file maps to exactly one GitHub Issue and one PR. The execution loop runs against one task file at a time.

## Work Phases — MANDATORY

Work follows three phases with hard gates between them. **You MUST NOT skip phases or combine them.**

### Phase 1: Planning (produces files and issues, NEVER code)

**Trigger:** User asks you to plan, design, or implement a feature.
**Constraint:** Do NOT write implementation code. Do NOT create feature branches. Only produce planning artifacts.

1. Follow the Socratic elicitation process in `spec/planning/spec.md` — ask clarifying questions until requirements are clear
2. Create a GitHub Milestone for the work
3. Write `plan/{milestone-name}/SPEC.md` — the what and why for the whole milestone
4. Write one task file per issue in `plan/{milestone-name}/tasks/{NN}-{issue-name}.tasks.md`
5. Create GitHub Issues (one per task file), linked to the Milestone
6. **STOP.** Tell the user: "Planning complete. Review the milestone, issues, and task files. When ready, use EXECUTE.prompt.md to begin implementation."

**What planning produces:**

- `plan/{milestone-name}/SPEC.md` — milestone-level specification
- `plan/{milestone-name}/tasks/*.tasks.md` — one task file per issue
- GitHub Milestone with linked Issues
- NO code, NO feature branches, NO file changes outside `plan/`

### Phase 2: Execution (one task at a time, one issue at a time)

**Trigger:** User invokes the execution prompt (see `EXECUTE.prompt.md`) for a specific task file.
**Constraint:** Only work on the next unchecked task in the specified task file. Do NOT skip ahead. Do NOT work across issues.

1. Read the specified task file (e.g., `plan/{milestone}/tasks/01-sre.tasks.md`)
2. Find the next unchecked `- [ ]` task
3. Read the task's spec references and context
4. Execute the task (create branch if first task, write code, verify)
5. Mark the task `- [x]` in the task file
6. **STOP.** Report what was done. The next invocation picks up the next task.

### Phase 3: Issue Completion

**Trigger:** All tasks in a task file are `[x]`.
**Action:** Create PR targeting `main`, referencing the GitHub Issue. Output `NO_MORE_TASKS_TO_PROCESS`.

The user then moves to the next task file (next issue) or reviews the PR first.

### Why This Matters

- **Context windows are finite.** Plans held only in memory are lost on compaction. Plans in files survive.
- **Stateless agents.** Each execution reads state from files, not from conversation history.
- **Reviewable.** The user can review, edit, and reorder tasks before execution begins.
- **Right-sized PRs.** One PR per issue is reviewable. One PR per milestone is not.
- **Reproducible.** Given the same SPEC.md and task files, the work can be re-executed.

## Git Workflow

- **Never commit directly to `main`** — pre-commit and pre-push hooks enforce this
- Create feature branches: `git checkout -b feat/<description>`
- Push feature branches and create PRs against `main`
- Branch naming convention: `feat/`, `fix/`, `chore/` prefixes
- **One branch per issue.** Each task file declares its branch name. All tasks within an issue are committed to the same branch.

## Planning

When planning work:

- Create GitHub Milestones for large pieces of work e.g. "Comprehensive Code Review Claude Plugin", "Threat Modelling Plugin", "Resilience Modelling Plugin" etc.
- Create GitHub Issues to define specific outcomes related to a Milestone
- If the work is not large enough for its own Milestone, ask which milestone it should belong to, or create a "v next" milestone
- Once planning is complete, the plan lives in `plan/{milestone-name}/` — NOT in conversation memory
- Use `spec/planning/spec.md` to guide the Socratic elicitation and artifact generation process

## Specifications

**IMPORTANT:** Before implementing any feature, consult the specifications in `spec/README.md`.

- **Assume NOT implemented.** Many specs describe planned features that may not yet exist in the codebase.
- **Check the codebase first.** Before concluding something is or isn't implemented, search the actual code. Specs describe intent; code describes reality.
- **Use specs as guidance.** When implementing a feature, follow the design patterns, types, and architecture defined in the relevant spec.
- **Spec index:** `spec/README.md` lists all specifications organized by category.
