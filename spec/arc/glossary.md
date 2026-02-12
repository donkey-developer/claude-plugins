# Glossary -- Architecture Domain

> Canonical definitions for all terms, frameworks, and acronyms used in the Architecture review domain. When writing or modifying prompts, use these definitions exactly.
>
> This glossary covers domain-specific terminology. For shared terms (maturity model, orchestration, output), see `../review-standards/glossary.md`.

## Frameworks

### C4-Inspired Zoom Levels

The structural framework that organises the Architecture review into four nested scopes, each with a dedicated subagent. Inspired by Simon Brown's C4 Model but adapted for code review rather than diagramming.

Origin: C4 Model (Simon Brown), adapted by the donkey-dev project for review decomposition.

| Zoom Level | Scope | Key Question |
|------------|-------|-------------|
| **Code** | Classes, functions, modules | Is the code well-structured? |
| **Service** | A deployable unit (one service/app) | Is the service well-designed? |
| **System** | Multiple services interacting | Do services work well together? |
| **Landscape** | Multiple systems / ecosystem | Does it fit the wider ecosystem? |

### Domain-Driven Design (DDD)

Eric Evans' framework for managing domain complexity through bounded contexts (strategic) and tactical patterns (entities, value objects, aggregates). Applied at the Code and Service zoom levels primarily, with Context Maps at the Landscape level.

Origin: Eric Evans, *Domain-Driven Design*, 2003.

### Release It!

Michael Nygard's stability patterns and anti-patterns for production-ready software. Provides the analytical lens for the System zoom level -- how services protect themselves from failure at integration points.

Origin: Michael T. Nygard, *Release It!*, 2nd Edition, 2018.

### Enterprise Integration Patterns (EIP)

Hohpe & Woolf's catalogue of messaging patterns for connecting distributed systems. Applied at the Landscape zoom level -- how systems integrate, route messages, and handle integration failures.

Origin: Gregor Hohpe & Bobby Woolf, *Enterprise Integration Patterns*, 2003.

### Modern Software Engineering

Dave Farley's framework for managing complexity through testability and deployability. Applied as cross-cutting principles at all zoom levels.

Origin: Dave Farley, *Modern Software Engineering*, 2021.

## Zoom Level Definitions

Each zoom level maps to one subagent and one prompt checklist.

### Code Level

**Scope:** Classes, functions, modules -- the innermost structural units.

**Primary concerns:** SOLID principles, DDD tactical patterns (Entities, Value Objects, Aggregates), code quality (testability, complexity, cohesion, coupling, naming).

**Key question:** "Is the code well-structured?"

**Framework sources:** SOLID (Martin), DDD Tactical (Evans), Modern Software Engineering (Farley).

### Service Level

**Scope:** A deployable unit -- one service, application, or independently-deployable component.

**Primary concerns:** Bounded context alignment, architecture & layering (dependency rule, ports & adapters), deployability, error model design.

**Key question:** "Is the service well-designed?"

**Framework sources:** DDD Strategic (Evans), Clean Architecture (Martin), Modern Software Engineering (Farley).

### System Level

**Scope:** Multiple services interacting -- the inter-service boundary.

**Primary concerns:** Stability patterns (circuit breaker, bulkhead, timeout, shed load, backpressure, fail fast, governor), API contracts & communication, coupling & cohesion at the service level.

**Key question:** "Do services work well together?"

**Framework sources:** Release It! (Nygard), EIP basics (Hohpe & Woolf).

### Landscape Level

**Scope:** Multiple systems, the wider ecosystem -- system-of-systems.

**Primary concerns:** DDD context maps, Enterprise Integration Patterns (message design, routing, transformation, error handling), architectural governance (ADRs, fitness functions, standards), design documentation traceability, evolution & change management.

**Key question:** "Does it fit the wider ecosystem?"

**Framework sources:** EIP (Hohpe & Woolf), DDD Context Maps (Evans), ADR pattern (Nygard, Keeling).

## Design Principle Terminology

### Domain-Driven Design Terms

| Term | Definition | Where evaluated |
|------|-----------|-----------------|
| **Bounded Context** | A domain boundary where a particular model applies; crossing requires explicit mapping. | Service, System, Landscape |
| **Ubiquitous Language** | Shared vocabulary between code and domain experts within a bounded context. | Code, Service |
| **Aggregate** | A cluster of domain objects treated as a single transactional unit with a root entity. | Code, Service |
| **Value Object** | An immutable object defined by its attributes, not by identity (e.g., Money, Address). | Code |
| **Domain Event** | A record of something significant that happened in the domain. | Code, Landscape |
| **Anti-Corruption Layer (ACL)** | A translation layer that prevents one system's model from leaking into another. | Service, System, Landscape |
| **Context Map** | A diagram showing relationships and integration patterns between bounded contexts. | Landscape |
| **Published Language** | A shared interchange format for cross-context communication. | Landscape |

### Stability Terms (Release It!)

| Term | Definition | Where evaluated |
|------|-----------|-----------------|
| **Circuit Breaker** | A pattern that stops calling a failing dependency after a threshold, allowing recovery. | System |
| **Bulkhead** | Compartmentalization to isolate failures (separate pools per dependency). | System |
| **Timeout** | Explicit time bound on inter-service calls. | System |
| **Shed Load** | Rejecting excess work to protect system stability under overload. | System |
| **Backpressure** | Mechanism for consumers to signal producers to slow down. | System |
| **Governor** | A rate-limiting mechanism controlling execution speed. | System |
| **Dogpile** | Thundering herd problem when many clients simultaneously retry or recache. | System |
| **Fail Fast** | Services reject known-bad requests immediately, refuse traffic when not ready. | System |

### Integration Terms (EIP)

| Term | Definition | Where evaluated |
|------|-----------|-----------------|
| **Message Channel** | A named conduit for moving messages between systems. | Landscape |
| **Message Router** | Logic determining which channel a message should follow. | Landscape |
| **Message Transformer** | Logic converting messages between formats. | Landscape |
| **Dead Letter Channel** | A destination for messages that cannot be processed. | Landscape |
| **Idempotent Consumer** | A consumer that safely handles duplicate messages. | Landscape |

### Governance Terms

| Term | Definition | Where evaluated |
|------|-----------|-----------------|
| **ADR** | Architecture Decision Record -- documents what was decided, why, and the consequences. | Landscape |
| **Fitness Function** | An automated test that validates an architectural characteristic is preserved. | Landscape |
| **Strangler Fig** | A migration pattern where new code gradually replaces old, running in parallel. | Landscape |

### Cross-Cutting Principles

These principles apply at all zoom levels and should be evaluated everywhere:

| Principle | Definition |
|-----------|-----------|
| **Separation of Concerns** | Each component should have a single, well-defined responsibility. |
| **Loose Coupling** | Minimize dependencies between components; depend on abstractions. |
| **High Cohesion** | Group related behavior together; keep unrelated behavior apart. |
| **Testability** | Design so that behavior can be verified automatically. |
| **Explicit over Implicit** | Make dependencies, contracts, and assumptions visible. |

## Maturity Model

This domain inherits the shared maturity model (see `../review-standards/glossary.md` and `../review-standards/review-framework.md`).

Domain-specific maturity context:

| Level | One-line description |
|-------|---------------------|
| **L1** | Foundations -- The system has clear structure and can be understood and tested. |
| **L2** | Hardening -- Architecturally mature. Integration contracts, design rationale, and failure containment exist. |
| **L3** | Excellence -- Best-in-class. Architecture is governed, validated automatically, and evolves incrementally. |

### Hygiene Gate (domain examples)

| Test | Architecture examples |
|------|----------------------|
| **Irreversible** | Two services writing directly to the same database tables (corrupted data). Circular dependency chain where extracting the cycle requires rewriting both modules. |
| **Total** | Synchronous circular dependency chain where one failure cascades to all participants. Deployment requires all services released simultaneously (shared fate). |
| **Regulated** | PII exposed through leaky abstraction in a public API response. System boundary that violates data residency requirements. |

### Severity Levels

| Level | Structural impact | Merge decision |
|-------|-------------------|----------------|
| **HIGH** | Fundamental design flaw -- systemic risk, shared mutable state, circular dependencies | Must fix before merge |
| **MEDIUM** | Design smell -- principle violation, leaky abstraction, missing documentation | May require follow-up ticket |
| **LOW** | Style improvement -- minor naming, minor restructuring | Nice to have |

Severity measures **structural consequence**, not implementation difficulty.
