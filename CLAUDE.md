# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A Code Review Plugin for Claude Code that enables generalist software engineers to extend their review capability across Architecture, Security, Site Reliability Engineering (SRE), and Data Engineering disciplines. The plugin provides slash commands (`review-all`, `review-sec`, `review-sre`, `review-arch`, `review-data`) that perform domain-specific code reviews with progressive level reporting.

## Work Phases — MANDATORY

All non-trivial work follows three phases with hard gates between them. **You MUST NOT skip phases or combine them.**

### Phase 1: Planning (produces files and issues, NEVER code)

**Trigger:** User asks you to plan, design, or implement a feature.
**Constraint:** Do NOT write implementation code. Do NOT create feature branches. Only produce planning artifacts.

1. Follow the Socratic elicitation process in `spec/planning/spec.md` — ask clarifying questions until requirements are clear
2. Create a GitHub Milestone for the work
3. Write `SPEC.md` in `plan/{feature-name}/SPEC.md` — the what and why
4. Write `TASKS.md` in `plan/{feature-name}/TASKS.md` — atomic, sequenced, dependency-aware tasks
5. Create GitHub Issues for each task, linked to the Milestone
6. **STOP.** Tell the user: "Planning complete. Review the milestone, issues, and plan files. When ready, use the execution prompt to begin implementation."

**What planning produces:**
- `plan/{feature-name}/SPEC.md` — specification file
- `plan/{feature-name}/TASKS.md` — task list with checkboxes
- GitHub Milestone with linked Issues
- NO code, NO feature branches, NO file changes outside `plan/`

### Phase 2: Execution (one task at a time from TASKS.md)

**Trigger:** User invokes the execution prompt (see `EXECUTE.prompt.md`).
**Constraint:** Only work on the next unchecked task in `TASKS.md`. Do NOT skip ahead.

1. Read `plan/{feature-name}/TASKS.md`
2. Find the next unchecked `- [ ]` task
3. Read the task's spec references and context
4. Execute the task (create branch if needed, write code, verify)
5. Mark the task `- [x]` in `TASKS.md`
6. **STOP.** Report what was done. The next invocation picks up the next task.

### Phase 3: Completion

**Trigger:** All tasks in `TASKS.md` are `[x]`.
**Action:** Create PR, run validation, output `NO_MORE_TASKS_TO_PROCESS`.

### Why This Matters

- **Context windows are finite.** Plans held only in memory are lost on compaction. Plans in files survive.
- **Stateless agents.** Each execution reads state from files, not from conversation history.
- **Reviewable.** The user can review, edit, and reorder tasks in `TASKS.md` before execution begins.
- **Reproducible.** Given the same `SPEC.md` and `TASKS.md`, the work can be re-executed.

## Git Workflow

- **Never commit directly to `main`** — pre-commit and pre-push hooks enforce this
- Create feature branches: `git checkout -b feat/<description>`
- Push feature branches and create PRs against `main`
- Branch naming convention: `feat/`, `fix/`, `chore/` prefixes

## Planning

When planning work:

- Create GitHub Milestones for large pieces of work e.g. "Comprehensive Code Review Claude Plugin", "Threat Modelling Plugin", "Resilience Modelling Plugin" etc.
- Create GitHub Issues to define specific outcomes related to a Milestone
- If the work is not large enough for its own Milestone, ask which milestone it should belong to, or create a "v next" milestone
- Once planning is complete, the plan lives in `plan/{feature-name}/` — NOT in conversation memory
- Use `spec/planning/spec.md` to guide the Socratic elicitation and artifact generation process

## Specifications

**IMPORTANT:** Before implementing any feature, consult the specifications in `spec/README.md`.

- **Assume NOT implemented.** Many specs describe planned features that may not yet exist in the codebase.
- **Check the codebase first.** Before concluding something is or isn't implemented, search the actual code. Specs describe intent; code describes reality.
- **Use specs as guidance.** When implementing a feature, follow the design patterns, types, and architecture defined in the relevant spec.
- **Spec index:** `spec/README.md` lists all specifications organized by category.
