# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A Code Review Plugin for Claude Code that enables generalist software engineers to extend their review capability across Architecture, Security, Site Reliability Engineering (SRE), and Data Engineering disciplines.
The plugin provides slash commands (`review-all`, `review-sec`, `review-sre`, `review-arch`, `review-data`) that perform domain-specific code reviews with progressive level reporting.

## Git Workflow

- **Never commit directly to `main`** — pre-commit and pre-push hooks enforce this
- Create feature branches: `git checkout -b feat/<description>`
- Push feature branches and create PRs against `main`
- Branch naming convention: `feat/`, `fix/`, `chore/` prefixes

## Specifications

**IMPORTANT:** Before implementing any feature, consult the specifications in `specs/README.md`.

- **Assume NOT implemented.** Many specs describe planned features that may not yet exist in the codebase.
- **Check the codebase first.** Before concluding something is or isn't implemented, search the actual code. Specs describe intent; code describes reality.
- **Use specs as guidance.** When implementing a feature, follow the design patterns, types, and architecture defined in the relevant spec.
- **Spec index:** `specs/README.md` lists all specifications organized by category (core, LLM, security, etc.).
