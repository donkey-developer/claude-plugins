# Specifications index

This file provides guidance on where to find standards and specifications for this project.

## Claude documentation

- Claude best practices and prompting tips: https://code.claude.com/docs/en/best-practices
- Claude Plugins: https://code.claude.com/docs/en/plugins and https://code.claude.com/docs/en/plugins-reference
- Claude Plugin Marketplace: https://code.claude.com/docs/en/plugin-marketplaces
- Agents: https://code.claude.com/docs/en/sub-agents
- Agent teams: https://code.claude.com/docs/en/agent-teams
- Skills and slash commands: https://code.claude.com/docs/en/skills
- Hooks: https://code.claude.com/docs/en/hooks-guide
- MCP: https://code.claude.com/docs/en/mcp
- Output styles: https://code.claude.com/docs/en/output-styles
- Claude Configuration and Settings: https://code.claude.com/docs/en/settings
- Claude Permissions models: https://code.claude.com/docs/en/permissions
- Claude Sandbox configuration: https://code.claude.com/docs/en/sandboxing

## Review standards and conventions

- Review standards framework, maturity model, severity, constraints, plugin file layout, compilation pipeline, agent input/output pattern, manifest-based input, file-based output, tool-driven discovery - ./review-standards/review-framework.md
- Review standards design principles, outcomes over techniques, questions over imperatives, positive observations, consequence-based hygiene, tool-driven discovery over content-dumping - ./review-standards/design-principles.md
- Review standards orchestration, scope identification, manifest generation, file-based agent output, sequential domain synthesis, deduplication, flat dispatch, batch naming, output directory structure - ./review-standards/orchestration.md
- Review standards glossary, maturity levels, status indicators, subagent, skill orchestrator, finding, maturity assessment, manifest, self-selection, tool-driven discovery, content-dumping, scope identification, full-codebase mode, diff mode, unified flow, batch, sequential synthesis - ./review-standards/glossary.md
- Review standards references, project history, cross-domain PRs, Twelve-Factor App - ./review-standards/references.md

## GitHub

- GitHub CLI reference, milestones, issues, pull requests, `gh api` commands, quick reference - ./github.md

## Domain-specific specification indexes

- SRE, Site Reliability Engineering, Availability, Observability, Incident Response, CI/CD, Deployment - ./domains/sre/spec.md
- Security, Confidentiality, Privacy, Threat, Vulnerability, Defence, Authorisation, Authentication, Audit - ./domains/security/spec.md
- Architecture, code, service, system, landscape, anti-patterns, standards, Performance, Cost, Affordability, Modular, Modularity, Composability, Composition, Scalability, Scale, Scalable, Modifiability, Modifiable, Portability, Integrability, Integration Reusability, Reuse, Testing - ./domains/architecture/spec.md
- Data, Governance, GDPR, CCPA, PII, Query, analytics, Warehouse, Database, Schema, Table, Column, Row, Pipeline, ETL, ELT, Transform, evaluations, data contract, polyseme, published, metrics, partition, JSON, freshness - ./domains/data/spec.md

## SRE domain detail files

- SRE anti-patterns, SEEMS failure modes, ROAD pillars, code examples — ./domains/sre/anti-patterns.md
- SRE calibration, severity examples, worked findings, judgement guidance — ./domains/sre/calibration.md
- SRE framework map, ROAD pillars, SEEMS/FaCTOR mapping, maturity criteria mapping — ./domains/sre/framework-map.md
- SRE glossary, ROAD, SEEMS, FaCTOR, SLO, error budget, canary — ./domains/sre/glossary.md
- SRE maturity criteria, L1/L2/L3 thresholds, pillar-by-pillar criteria — ./domains/sre/maturity-criteria.md
- SRE references, source attribution, frameworks, Twelve-Factor App — ./domains/sre/references.md

## Security domain detail files

- Security anti-patterns, STRIDE examples, injection, auth bypass, code snippets — ./domains/security/anti-patterns.md
- Security calibration, DREAD-lite worked examples, confidence thresholds — ./domains/security/calibration.md
- Security framework map, STRIDE threats, security properties, pillar mapping — ./domains/security/framework-map.md
- Security glossary, STRIDE, DREAD-lite, exploit path, confidence threshold, CIA triad — ./domains/security/glossary.md
- Security maturity criteria, AuthN/AuthZ, data protection, input validation, audit — ./domains/security/maturity-criteria.md
- Security references, OWASP, STRIDE, DREAD, source attribution — ./domains/security/references.md

## Architecture domain detail files

- Architecture anti-patterns, C4 zoom levels, coupling, cohesion, god class, distributed monolith — ./domains/architecture/anti-patterns.md
- Architecture calibration, severity examples, zoom-level scaling, design judgement — ./domains/architecture/calibration.md
- Architecture framework map, C4 model, zoom levels, quality attributes mapping — ./domains/architecture/framework-map.md
- Architecture glossary, C4, zoom level, coupling, cohesion, quality attributes, erosion — ./domains/architecture/glossary.md
- Architecture maturity criteria, L1/L2/L3 by zoom level, structural thresholds — ./domains/architecture/maturity-criteria.md
- Architecture references, C4 model, ISO 25010, source attribution — ./domains/architecture/references.md

## Data domain detail files

- Data anti-patterns, quality decay patterns, SQL examples, pipeline smells — ./domains/data/anti-patterns.md
- Data calibration, consumer-first perspective, worked severity examples — ./domains/data/calibration.md
- Data framework map, four pillars, quality dimensions, decay patterns mapping — ./domains/data/framework-map.md
- Data glossary, data contract, polyseme, freshness, lineage, partition, published metric — ./domains/data/glossary.md
- Data maturity criteria, L1/L2/L3 per pillar, data-specific thresholds — ./domains/data/maturity-criteria.md
- Data references, DAMA-DMBOK, dbt, data mesh, source attribution — ./domains/data/references.md
