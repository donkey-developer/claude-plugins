# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A Code Review Plugin for Claude Code that enables generalist software engineers to extend their review capability across Architecture, Security, Site Reliability Engineering (SRE), and Data Engineering disciplines. The plugin provides slash commands (`review-all`, `review-sec`, `review-sre`, `review-arch`, `review-data`) that perform domain-specific code reviews with progressive level reporting.

## Git Workflow

- **Never commit directly to `main`** — pre-commit and pre-push hooks enforce this
- Create feature branches: `git checkout -b feat/<description>`
- Push feature branches and create PRs against `main`
- Branch naming convention: `feat/`, `fix/`, `chore/` prefixes
