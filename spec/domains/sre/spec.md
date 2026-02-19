# SRE Domain Specification

> Canonical reference for building, improving, and maintaining the SRE review domain within the donkey-dev Claude Code plugin.

## 1. Purpose

The SRE review domain evaluates code changes through the lens of operational reliability. It answers one question: **"If we ship this, what will 3am look like?"**

The domain produces a structured maturity assessment that tells engineering leaders:
- What will break in production (Hygiene failures)
- What foundations are missing (L1 gaps)
- What operational maturity looks like for this codebase (L2 criteria)
- What excellence would require (L3 aspirations)

## 2. Audience

This domain inherits the shared audience definitions (see `../../review-standards/review-framework.md`).

## 3. Conceptual Architecture

The SRE domain is built from three interlocking layers:

```
+----------------------------------------------+
|          ROAD Framework (Structure)          |   Organises WHAT to review
|  Response . Observability .                  |
|  Availability . Delivery                     |
+----------------------------------------------+
|    SEEMS (Attack)  <-->  FaCTOR (Defence)    |   Analytical LENSES
|    "How will this      "What protects        |
|     fail?"              against it?"         |
+----------------------------------------------+
|         Maturity Model (Judgement)            |   Calibrates SEVERITY
|    Hygiene --> L1 --> L2 --> L3               |   and PRIORITY
+----------------------------------------------+
```

- **ROAD** provides the structural decomposition (4 pillars, 4 subagents).
- **SEEMS** and **FaCTOR** provide the analytical lenses applied within each pillar.
- **The Maturity Model** provides the judgement framework for prioritising findings.

These layers are defined in detail in the companion files:
- `glossary.md` — canonical definitions
- `framework-map.md` — how SEEMS, FaCTOR, and ROAD relate to each other
- `maturity-criteria.md` — detailed criteria with "sufficient" thresholds
- `calibration.md` — worked examples showing severity judgement
- `anti-patterns.md` — concrete code smells per pillar
- `references.md` — source attribution

## 4. File Layout

This domain inherits the shared plugin file layout (see `../../review-standards/review-framework.md`). Domain-specific files:

| Location | File | Purpose |
|----------|------|---------|
| `agents/` | `sre-response.md` | Subagent: incident response readiness |
| `agents/` | `sre-observability.md` | Subagent: logging, metrics, tracing |
| `agents/` | `sre-availability.md` | Subagent: SLOs, resilience, load management |
| `agents/` | `sre-delivery.md` | Subagent: deployment safety, rollback |
| `prompts/sre/` | `_base.md` | Shared context: SEEMS, FaCTOR, maturity model, output format |
| `prompts/sre/` | `response.md` | Response pillar checklist |
| `prompts/sre/` | `observability.md` | Observability pillar checklist |
| `prompts/sre/` | `availability.md` | Availability pillar checklist |
| `prompts/sre/` | `delivery.md` | Delivery pillar checklist |
| `skills/` | `sre/SKILL.md` | Orchestrator: scope, parallel dispatch, synthesis, output |

## 5. Design Principles

This domain inherits the shared design principles (see `../../review-standards/design-principles.md`) and adds domain-specific principles and examples below.

### 5.1 Outcomes over techniques (domain examples)

| Bad (technique) | Good (outcome) |
|-----------------|----------------|
| "Circuit breakers exist" | "External dependencies have failure isolation" |
| "Uses structured logging" | "Logging is structured with request correlation" |
| "Has Prometheus metrics" | "SLI-relevant metrics are exposed and measurable" |
| "Implements SEEMS/FaCTOR" | "Failure modes are identified and resilience properties verified" |

### 5.2 Questions over imperatives (domain examples)

| Bad (imperative) | Good (question) |
|-------------------|-----------------|
| "Ensure requests are traceable" | "Can you trace a request through the system?" |
| "Add timeouts to all calls" | "Do all external calls have timeouts? Are they appropriate?" |

### 5.3 Concrete anti-patterns (domain examples)

| Bad (abstract) | Good (concrete) |
|-----------------|-----------------|
| "Poor error handling" | "Generic error messages: 'An error occurred' / 'Something went wrong'" |
| "Inadequate logging" | "`console.log` / `print` statements instead of structured logging" |

### 5.4 Severity is about production impact

| Level | Definition | Decision |
|-------|-----------|----------|
| **HIGH** | Could cause outage, data loss, or significant degradation | Must fix before merge |
| **MEDIUM** | Operational risk that should be addressed | May require follow-up ticket |
| **LOW** | Minor improvement opportunity | Nice to have |

Severity is about the **production consequence** if the code ships as-is, not about how hard the fix is.

### 5.5 Positive observations with code evidence

The SRE review instructions require a "What's Good" section identifying operational patterns worth preserving.
Each positive observation must cite specific file references (e.g. `src/health.ts:12`) and concrete evidence such as structured logging, timeout configuration, graceful degradation paths, health check implementations, or error handling that aids diagnosis.
Generic praise without code evidence is prohibited.

## 6. Orchestration Process

The `/donkey-review:sre` skill follows the shared orchestration pattern (see `../../review-standards/orchestration.md`) with these domain-specific details:

### Step 2: Parallel dispatch

Spawn 4 subagents simultaneously:

| Agent | Model | Rationale |
|-------|-------|-----------|
| `sre-response` | sonnet | Nuanced judgement on error message quality and runbook readiness |
| `sre-observability` | sonnet | Complex analysis of logging/metrics/tracing completeness |
| `sre-availability` | sonnet | Subtle resilience pattern analysis |
| `sre-delivery` | haiku | More binary checklist (backward-compatible or not, reversible or not) |

### Step 3: Synthesis

Follows the shared synthesis algorithm (see `../../review-standards/orchestration.md`). No domain-specific synthesis additions.

## 7. Improvement Vectors

Known gaps that future work should address, in priority order:

| # | Gap | Impact | Direction |
|---|-----|--------|-----------|
| 1 | **SEEMS-FaCTOR duality unlinked** | Reviewers treat them as separate checklists | Add explicit mapping: "this SEEMS failure is mitigated by this FaCTOR property" (see `framework-map.md`) |
| 2 | **No calibration examples** | Severity judgements are inconsistent across runs | Add worked examples per severity per pillar (see `calibration.md`) |
| 3 | **L1 "sufficient" is undefined** | "Errors propagate with context sufficient for diagnosis" is subjective | Define minimum thresholds (see `maturity-criteria.md`) |
| 4 | **Deduplication rules were implicit** | Synthesis step produced inconsistent merges | Now defined in Section 6 above |
| 5 | **No technology-specific supplements** | Checklists can't recognise framework-specific patterns | Future: add optional supplements for Python, Java, Go, Node, .NET |
| 6 | **SLO treatment is shallow** | SLOs mentioned but not operationalised | Future: add concrete guidance on SLO-aligned code patterns |
| 7 | **No confidence signal** | Agents can't express uncertainty | Future: add optional confidence qualifier (confirmed / likely / possible) |
| 8 | **No cross-review learning** | Each review is stateless | Future: use `.donkey-review/` history to track maturity progression |

## 8. Constraints

This domain inherits the universal constraints (see `../../review-standards/review-framework.md`). No domain-specific constraints beyond the universal set.
