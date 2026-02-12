# Architecture Domain Specification

> Canonical reference for building, improving, and maintaining the Architecture review domain within the donkey-dev Claude Code plugin.

## 1. Purpose

The Architecture review domain evaluates code changes through the lens of structural design. It answers one question: **"If we build this, will it age well?"**

The domain produces a structured maturity assessment that tells engineering leaders:
- What structural damage is accumulating (Hygiene failures)
- What design foundations are missing (L1 gaps)
- What architectural maturity looks like for this codebase (L2 criteria)
- What excellence would require (L3 aspirations)

Architecture focuses on **design-time decisions** — the choices that determine how easy the system is to understand, change, test, and extend. It complements the SRE domain (run-time behaviour), Security domain (threat exposure), and Data domain (data product quality).

## 2. Audience

This domain inherits the shared audience definitions (see `../review-standards/review-framework.md`).

## 3. Conceptual Architecture

The Architecture domain is built from three interlocking layers:

```
+----------------------------------------------+
|     C4-Inspired Zoom Levels (Structure)       |   Organises WHAT to review
|  Code . Service . System . Landscape          |   at increasing scope
+----------------------------------------------+
|    Design Principles  <-->  Erosion Patterns  |   Analytical LENSES
|    "What should this       "How does this     |
|     look like?"             go wrong?"        |
+----------------------------------------------+
|         Maturity Model (Judgement)             |   Calibrates SEVERITY
|    Hygiene --> L1 --> L2 --> L3                |   and PRIORITY
+----------------------------------------------+
```

- **Zoom Levels** provide the structural decomposition (4 levels, 4 subagents). Each level examines the system at a different scope — from individual modules to ecosystem-wide integration.
- **Design Principles** and **Erosion Patterns** provide the analytical duality. Principles describe what good architecture looks like; erosion patterns describe how architecture degrades. See `framework-map.md` for the complete mapping.
- **The Maturity Model** provides the judgement framework for prioritising findings.

These layers are defined in detail in the companion files:
- `glossary.md` — canonical definitions
- `framework-map.md` — how zoom levels, frameworks, and principles relate to each other
- `maturity-criteria.md` — detailed criteria with "sufficient" thresholds
- `calibration.md` — worked examples showing severity judgement
- `anti-patterns.md` — concrete code smells per zoom level
- `references.md` — source attribution

## 4. File Layout

This domain inherits the shared plugin file layout (see `../review-standards/review-framework.md`). Domain-specific files:

| Location | File | Purpose |
|----------|------|---------|
| `agents/` | `arch-code.md` | Subagent: SOLID, DDD tactical, testability |
| `agents/` | `arch-service.md` | Subagent: bounded contexts, layering, deployability |
| `agents/` | `arch-system.md` | Subagent: stability patterns, API contracts, coupling |
| `agents/` | `arch-landscape.md` | Subagent: integration patterns, context maps, ADRs |
| `prompts/architecture/` | `_base.md` | Shared context: zoom levels, glossary, maturity model, output format |
| `prompts/architecture/` | `code.md` | Code zoom level checklist |
| `prompts/architecture/` | `service.md` | Service zoom level checklist |
| `prompts/architecture/` | `system.md` | System zoom level checklist |
| `prompts/architecture/` | `landscape.md` | Landscape zoom level checklist |
| `skills/` | `review-arch/SKILL.md` | Orchestrator: scope, parallel dispatch, synthesis, output |

## 5. Design Principles

This domain inherits the shared design principles (see `../review-standards/design-principles.md`) and adds domain-specific principles and examples below.

### 5.1 Outcomes over techniques (domain examples)

| Bad (technique) | Good (outcome) |
|-----------------|----------------|
| "Uses DDD" | "Module boundaries are explicit with defined public interfaces" |
| "Implements Clean Architecture" | "Dependencies flow inward — infrastructure depends on domain, not vice versa" |
| "Has circuit breakers" | "External dependencies have failure isolation" |
| "Uses ADRs" | "Design decisions are documented with rationale and trade-offs" |
| "Follows SOLID" | "Components can be tested in isolation" |

### 5.2 Questions over imperatives (domain examples)

| Bad (imperative) | Good (question) |
|-------------------|-----------------|
| "Apply dependency inversion" | "Does business logic import infrastructure (database, HTTP, filesystem)?" |
| "Document architectural decisions" | "Are significant decisions documented with rationale?" |
| "Use bounded contexts" | "Does each service serve one cohesive domain concept?" |

### 5.3 Concrete anti-patterns (domain examples)

| Bad (abstract) | Good (concrete) |
|-----------------|-----------------|
| "Poor separation of concerns" | "Domain class imports ORM: `from sqlalchemy import Column` in `Order` entity" |
| "High coupling" | "Module A imports Module B which imports Module A (circular dependency)" |
| "Leaky abstraction" | "`@Entity` annotations on domain classes — persistence details in the domain layer" |

### 5.4 Severity is about structural impact

| Level | Definition | Decision |
|-------|-----------|----------|
| **HIGH** | Fundamental design flaw — systemic risk that will compound over time | Must fix before merge |
| **MEDIUM** | Design smell — principle violation with localised impact | May require follow-up ticket |
| **LOW** | Style improvement — minor suggestion, no structural risk | Nice to have |

Severity measures the **structural consequence** if the design ships as-is — how much harder will the system be to change, test, and operate. Not how hard the fix is.

### 5.5 Zoom levels scale to project size

Not every project operates at all zoom levels. The Architecture review adapts:
- **Small project / monolith**: Code + Service always apply. System + Landscape may return "no findings" — that's correct, not a gap.
- **Microservices**: All four levels should produce meaningful findings.
- **Library / SDK**: Code is primary, Service may partially apply.

Agents should not fabricate findings to fill a level. "No findings at this zoom level" is a valid and desirable output for projects where the level doesn't apply.

### 5.6 Design-time focus

Architecture reviews evaluate **design-time decisions**, not run-time behaviour. When a finding could be claimed by either Architecture or SRE, the distinction is:

| Concept | Architecture asks | SRE asks |
|---------|-------------------|----------|
| Circuit Breaker | "Is this the right pattern?" | "Is it configured and monitored?" |
| Coupling | "Is the dependency appropriate?" | "Does it cause cascading failure?" |
| Error handling | "Is the error model well-designed?" | "Can operators diagnose from errors?" |
| Deployability | "Is it independently deployable?" | "Can it be safely rolled out?" |

## 6. Orchestration Process

The `/review-arch` skill follows the shared orchestration pattern (see `../review-standards/orchestration.md`) with these domain-specific details:

### Step 2: Parallel dispatch

Spawn 4 subagents simultaneously:

| Agent | Model | Rationale |
|-------|-------|-----------|
| `arch-code` | sonnet | Nuanced judgement on SOLID compliance, DDD tactical correctness, and code quality assessment |
| `arch-service` | sonnet | Complex analysis of bounded context alignment, layering violations, and deployability |
| `arch-system` | sonnet | Subtle inter-service coupling analysis, stability pattern evaluation |
| `arch-landscape` | sonnet | Complex governance analysis, context map evaluation, ADR/spec traceability |

**Model selection rationale:** All four Architecture agents use sonnet because architectural review requires nuanced design judgement at every level. Unlike Security or SRE where some pillars have more binary criteria (present/absent), all architecture levels require interpreting code structure against design principles — a fundamentally interpretive task.

### Step 3: Synthesis

Follows the shared synthesis algorithm (see `../review-standards/orchestration.md`). No domain-specific synthesis additions.

## 7. Improvement Vectors

Known gaps that future work should address, in priority order:

| # | Gap | Impact | Direction |
|---|-----|--------|-----------|
| 1 | **No calibration examples in prompts** | Severity judgements are inconsistent across runs — the same God class might be HIGH in one review and MEDIUM in another | Add worked examples per severity per zoom level (see `calibration.md` in this spec) |
| 2 | **Zoom level overlap on coupling** | Code-level coupling and System-level coupling are different concerns but reviewers sometimes conflate them | Clarify boundary: Code owns intra-module coupling (class-to-class), System owns inter-service coupling (service-to-service). Document in `framework-map.md` |
| 3 | **L1 "sufficient" is undefined** | "Module boundaries are explicit with defined public interfaces" is subjective — what counts as explicit? | Define minimum thresholds (see `maturity-criteria.md`) |
| 4 | **Landscape level over-reports on small projects** | Landscape agent sometimes flags "missing ADRs" on single-file scripts | Improve scaling guidance: agent should assess project size before reporting L2/L3 governance criteria |
| 5 | **No technology-specific supplements** | Checklists can't recognise framework-specific patterns (e.g., Django vs Spring DI conventions) | Future: add optional supplements for Python, Java, Go, Node, .NET |
| 6 | **DDD tactical assessment is shallow** | The code-level DDD checklist identifies Value Objects and Aggregates but doesn't evaluate their correctness deeply | Future: add concrete guidance on aggregate sizing, eventual consistency boundaries, event design |
| 7 | **No design-decision impact analysis** | Reviews identify what's wrong but don't estimate the cost of the architectural debt | Future: add optional "change cost" qualifier (trivial / moderate / significant refactor) |
| 8 | **No cross-review learning** | Each review is stateless | Future: use `.code-review/` history to track architectural maturity progression |

## 8. Constraints

This domain inherits the universal constraints (see `../review-standards/review-framework.md`) and adds:

- **No prescribing specific patterns by name.** Do not require "DDD" or "Clean Architecture" or "Hexagonal Architecture". Describe the structural property the code should exhibit. The team may achieve it through any approach.
- **No fabricating findings.** If a zoom level doesn't apply to the project (e.g., Landscape for a single-service monolith), return "no findings" — do not invent concerns to fill the report.
