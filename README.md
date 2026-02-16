# Donkey Developer — Claude Plugins

## Overview

A **marketplace** of plugins for [Claude Code](https://code.claude.com/docs/en/overview).

The marketplace catalogue (`.claude-plugin/marketplace.json`) registers each plugin available in this repository.
Each plugin lives under `plugins/<name>/` with its own manifest, skills, agents, and prompts.

## Marketplace Structure

```text
.claude-plugin/
└── marketplace.json                ← Catalogue of available plugins

plugins/<name>/
├── .claude-plugin/plugin.json      ← Plugin manifest (name, version, description)
├── skills/{domain}/SKILL.md        ← Orchestrators (user-triggered slash commands)
├── agents/{domain}-{pillar}.md     ← Self-contained subagents (compiled, not hand-edited)
├── prompts/                        ← Source of truth (human-editable)
│   ├── shared/                     ← Cross-domain content
│   └── {domain}/                   ← Domain-specific content
└── scripts/
    └── compile.sh                  ← Builds agents and skills from prompt sources
```

Agents are **compiled** — `scripts/compile.sh` concatenates shared and domain prompts into self-contained agent files.
A pre-commit hook runs `compile.sh --check` to ensure compiled output stays in sync with prompt sources.

## Plugins

### code-review

Domain-specific code reviews across Architecture, Security, SRE, and Data Engineering.

**Features:**

- Comprehensive code review across four domains with 16 specialist subagents
- Critical hygiene warnings
- Progressive level reporting, allowing you to focus on the next-best-action
- Summary roll-up reporting for leadership oversight of system health and maturity

**Slash commands:**

- `/code-review:all` — run all four domain reviews and produce a combined report
- `/code-review:sre` — SRE review (response, observability, availability, delivery)
- `/code-review:security` — Security review (authn/authz, data protection, input validation, audit & resilience)
- `/code-review:architecture` — Architecture review (code, service, system, landscape)
- `/code-review:data` — Data Engineering review (architecture, engineering, quality, governance)

## Installation

Prerequisites: [Claude Code](https://code.claude.com/docs/en/overview) must be installed.

Add the marketplace:

```bash
/plugin marketplace add https://github.com/donkey-developer/claude-plugins.git
```

Install the code-review plugin:

```bash
/plugin install code-review@donkey-developer
```

## Usage

Run a comprehensive code review:

```bash
/code-review:all
```

This dispatches all 16 subagents in parallel, then synthesises the results into a combined report.

Run a single domain review:

```bash
/code-review:sre
```

Output reports are written to `.code-review/<batch-name>/` in your working directory.

## Configuration

**TODO** — configuration options will be documented as the plugin matures.

## Development

### Planning

Start an interactive planning session.
The agent follows `PLAN.prompt.md` using Socratic elicitation to generate a plan folder with a master _BRIEF.md_ and specific task files.
A GitHub Milestone for the planned work with each task file having a target GitHub Issue.
No code is written.

```bash
./scripts/plan.sh
./scripts/plan.sh "Build the code review plugin"
```

Or interactively in Claude Code:

```claude
Follow PLAN.prompt.md
```

### Execution

**Run a single task** (interactive, one at a time):

```claude
Follow EXECUTE.prompt.md for plan/{milestone}/tasks/01-scaffolding.tasks.md
```

**Run all tasks for a single issue** (automated Ralph Wiggum loop):

```bash
./scripts/execute-issue.sh plan/{milestone}/tasks/01-scaffolding.tasks.md
```

**Run all issues for a milestone** (automated, sequential):

```bash
./scripts/execute-milestone.sh plan/{milestone}/tasks
```

For parallel issues, run their `execute-issue.sh` loops concurrently instead of using the sequential milestone script. The last task file (`*-close.tasks.md`) handles milestone completion — updating specs, deleting the plan directory, and closing the GitHub Milestone.

## Testing

**TODO**

## Contributing

Guidelines for contributing to this project.

## License

[Choose a license]

## Authors

- Lee Campbell [LeeCampbell.com](https://leecampbell.com)
- Claude Code with Opus 4.6

## Support

How to get help or report issues.
