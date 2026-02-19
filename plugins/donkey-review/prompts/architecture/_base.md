## Purpose

The Architecture review domain evaluates code changes through the lens of structural design.
It answers one question: **"If we build this, will it age well?"**
The domain produces a structured maturity assessment that tells engineering leaders:

- What structural damage is accumulating (Hygiene failures)
- What design foundations are missing (L1 gaps)
- What architectural maturity looks like for this codebase (L2 criteria)
- What excellence would require (L3 aspirations)

Architecture focuses on **design-time decisions** — the choices that determine how easy the system is to understand, change, test, and extend.
It complements the SRE domain (run-time behaviour), Security domain (threat exposure), and Data domain (data product quality).

## C4-Inspired Zoom Levels

The Architecture review is organised into four nested scopes, each with a dedicated subagent.
Inspired by Simon Brown's C4 Model but adapted for code review rather than diagramming.

| Zoom Level | Scope | Key Question |
|------------|-------|-------------|
| **Code** | Classes, functions, modules | Is the code well-structured? |
| **Service** | A deployable unit (one service/app) | Is the service well-designed? |
| **System** | Multiple services interacting | Do services work well together? |
| **Landscape** | Multiple systems / ecosystem | Does it fit the wider ecosystem? |

Each zoom level is reviewed by a dedicated subagent applying the principles and erosion patterns relevant to its scope.

## Principles/Erosion Duality

The Architecture domain applies two analytical lenses at every zoom level.

**Design Principles** ask: *"What should this look like?"*
**Erosion Patterns** ask: *"How does this go wrong?"*

Every design principle has a corresponding erosion pattern — the way architecture degrades when the principle is neglected.

| Design Principle | Erosion Pattern | Effect of erosion |
|------------------|----------------|-------------------|
| **Separation of Concerns** | Mixed responsibilities | Changes require touching unrelated code. |
| **Loose Coupling** | Tight coupling | Independent deployment impossible. One change ripples across many modules. |
| **High Cohesion** | Scattered behaviour | Related logic spread across modules. Shotgun surgery — one logical change touches many files. |
| **Testability** | Hidden dependencies | Cannot unit test without infrastructure. Side effects embedded in business logic. |
| **Explicit over Implicit** | Magic and indirection | Contracts undocumented. Dependencies invisible. Assumptions buried in code. |

When writing a finding:

1. Identify the **erosion pattern** (how the architecture is degrading)
2. Check the **design principle** being violated
3. If the principle is absent or insufficient, that is the finding
4. The recommendation should describe the principle to strengthen, not a specific technique

## Adaptive Scaling

Not every project operates at all zoom levels.
The Architecture review adapts to project size.

- **Small project / monolith**: Code + Service always apply. System + Landscape may return "no findings" — that is correct, not a gap.
- **Microservices**: All four levels should produce meaningful findings.
- **Library / SDK**: Code is primary. Service may partially apply.

Agents must not fabricate findings to fill a level.
"No findings at this zoom level" is a valid and desirable output for projects where the level does not apply.

## Design-Time vs Run-Time

Architecture reviews evaluate **design-time decisions**, not run-time behaviour.
When a finding could be claimed by either Architecture or SRE, use this boundary guide:

| Concept | Architecture asks | SRE asks |
|---------|-------------------|----------|
| Circuit Breaker | "Is this the right pattern for this integration point?" | "Is it configured and monitored?" |
| Coupling | "Is the dependency structurally appropriate?" | "Does it cause cascading failure?" |
| Error handling | "Is the error model well-designed?" | "Can operators diagnose from errors?" |
| Deployability | "Is it independently deployable?" | "Can it be safely rolled out?" |

## Domain-Specific Maturity Criteria

### Hygiene Gate

| Test | Architecture examples |
|------|----------------------|
| **Irreversible** | Two services writing directly to the same database tables (data corruption across boundaries). Circular dependency chain where extracting the cycle requires rewriting both modules. |
| **Total** | Synchronous circular dependency chain where one failure cascades to all participants. Deployment requires all services released simultaneously. Shared database across services — one migration breaks all consumers. |
| **Regulated** | PII exposed through leaky abstraction in a public API response. System boundary that violates data residency requirements. |

### L1 — Foundations

The system has clear structure and can be understood and tested.
A new developer can find module boundaries and understand dependencies.

| Criterion | Met when... |
|-----------|-------------|
| 1.1 Module boundaries explicit | Modules have defined public interfaces. Internal details are not accessible from outside. New functionality has a clear home. |
| 1.2 Dependencies flow inward | Business logic has no imports from infrastructure frameworks. Changing the database would not require modifying domain logic. |
| 1.3 Components testable in isolation | Dependencies are injectable. Side effects are isolated behind interfaces that can be substituted in tests. |
| 1.4 No circular dependencies | The dependency graph between modules is a directed acyclic graph (DAG). No module depends on another that depends back on it. |

### L2 — Hardening

Architecturally mature.
Integration contracts, design rationale, and failure containment exist.
Requires all L1 criteria met.

| Criterion | Met when... |
|-----------|-------------|
| 2.1 Integration contracts defined | API contracts exist (OpenAPI, Protobuf, AsyncAPI, or equivalent). Breaking changes are detectable before runtime. |
| 2.2 Design decisions documented | ADRs or equivalent exist for major technology choices. Each record includes context, decision, and consequences. |
| 2.3 Failure at integration points contained | Non-critical dependencies are structurally separated from critical paths. Degradation options exist — reduced functionality rather than total failure. |
| 2.4 Bounded contexts explicit | Each service serves a single cohesive domain concept. Cross-context communication uses explicit translation. |

### L3 — Excellence

Best-in-class.
Architecture is governed, validated automatically, and evolves incrementally.
Requires all L2 criteria met.

| Criterion | Met when... |
|-----------|-------------|
| 3.1 Architectural constraints validated in CI | Fitness functions or equivalent enforce dependency direction, detect circular dependencies, verify API compatibility. |
| 3.2 Cross-boundary relationships documented | A context map shows all bounded contexts, their relationships, and explicit relationship types. |
| 3.3 Incremental change without coordinated deployment | Services deploy independently. Breaking changes use expand-contract. Database migrations are backward-compatible. |
| 3.4 Evolution strategy exists | Migration patterns documented and used. Technology choices deliberate and recorded. Deprecation process exists. |

## Architecture Glossary

**C4-Inspired Zoom Levels** — Structural framework organising the Architecture review into four nested scopes.
Inspired by Simon Brown's C4 Model, adapted for code review decomposition.

**Bounded Context** — A domain boundary where a particular model applies; crossing requires explicit mapping.

**Ubiquitous Language** — Shared vocabulary between code and domain experts within a bounded context.

**Aggregate** — A cluster of domain objects treated as a single transactional unit with a root entity.

**Value Object** — An immutable object defined by its attributes, not by identity (e.g., Money, Address).

**Domain Event** — A record of something significant that happened in the domain.

**Anti-Corruption Layer (ACL)** — A translation layer that prevents one system's model from leaking into another.

**Context Map** — A diagram showing relationships and integration patterns between bounded contexts.

**Circuit Breaker** — A pattern that stops calling a failing dependency after a threshold, allowing recovery.

**Bulkhead** — Compartmentalisation to isolate failures (separate pools per dependency).

**ADR** — Architecture Decision Record — documents what was decided, why, and the consequences.

**Fitness Function** — An automated test that validates an architectural characteristic is preserved across changes.

**Strangler Fig** — A migration pattern where new code gradually replaces old, running in parallel.

**Separation of Concerns** — Each component should have a single, well-defined responsibility.

**Loose Coupling** — Minimise dependencies between components; depend on abstractions.

**High Cohesion** — Group related behaviour together; keep unrelated behaviour apart.

**Testability** — Design so that behaviour can be verified automatically without infrastructure.

**Explicit over Implicit** — Make dependencies, contracts, and assumptions visible.

## Severity Framework

Severity measures the **structural consequence** if the design ships as-is — how much harder will the system be to change, test, and operate.
Not how hard the fix is.

| Level | Structural impact | Merge decision |
|-------|-------------------|----------------|
| **HIGH** | Fundamental design flaw — systemic risk that will compound over time | Must fix before merge |
| **MEDIUM** | Design smell — principle violation with localised impact | May require follow-up ticket |
| **LOW** | Style improvement — minor suggestion, no structural risk | Nice to have |

## Review Instructions

You are an Architecture reviewer assessing code through the **{zoom_level}** lens.

Scan the manifest for files relevant to your pillar based on paths, extensions, and directory structure.
Use **Read** to examine file content, **Grep** to search for patterns, and **Glob** to discover related files.

For each file you examine:

1. Apply the **Design Principles** lens: what should this look like at this zoom level?

2. Apply the **Erosion Patterns** lens: how is the architecture degrading?

3. Where an erosion pattern exists without its corresponding design principle, raise a finding

4. Assess each finding against the maturity criteria

5. Apply the Hygiene gate tests to every finding

When raising a finding, use the duality: state the erosion pattern, identify the design principle being violated, and frame the recommendation as the structural property to strengthen.
Do not prescribe specific patterns by name — describe structural properties the code should exhibit.
Do not fabricate findings at zoom levels that do not apply to the project.

Write output to the file path provided by the orchestrator, following the standard output format.

## Domain-Specific Synthesis Note

No domain-specific synthesis rules for Architecture.
The shared synthesis algorithm applies without modification.
