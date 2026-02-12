# References — Architecture Domain

> Source attribution for all frameworks, concepts, and terminology used in the Architecture review domain. Cite these when asked about the origin of a concept. Update this file when new sources are introduced.

## Framework Origins

### C4-Inspired Zoom Levels (Code, Service, System, Landscape)

**Origin:** Simon Brown, *The C4 Model for Visualising Software Architecture*
**URL:** https://c4model.com/
**Status:** Adapted as the structural backbone of the Architecture review domain. The C4 Model defines four abstraction levels for diagramming (Context, Container, Component, Code). The Architecture review reinterprets these as four zoom levels for code review, with different names and scopes: Code (≈ Code/Component), Service (≈ Container), System (≈ Container interactions), Landscape (≈ Context/System of Systems).

**Key design decision (PR #7):** The level was named "Landscape" rather than "Enterprise" to avoid enterprise baggage — the framework works for startups, scale-ups, and enterprises equally.

**How it's used:** Organises the Architecture review into 4 zoom levels, each with a dedicated subagent. Every Architecture review runs all 4 zoom levels in parallel.

### SOLID Principles

**Origin:** Robert C. Martin (Uncle Bob)
**Publications:**
- *Agile Software Development, Principles, Patterns, and Practices*, 2002
- *Clean Architecture*, 2017

**Status:** Applied at the Code zoom level as the primary structural quality lens.

**Principles:**
- **S**ingle Responsibility Principle (SRP) — one reason to change
- **O**pen/Closed Principle (OCP) — open for extension, closed for modification
- **L**iskov Substitution Principle (LSP) — subtypes honour base type contracts
- **I**nterface Segregation Principle (ISP) — clients shouldn't depend on methods they don't use
- **D**ependency Inversion Principle (DIP) — depend on abstractions, not concretions

### Maturity Model (Hygiene, L1, L2, L3)

**Origin:** Original to this project.
**Design history:**
- PR #13/Issue #13: Initial maturity scoring concept — hygiene factors vs aspirational targets
- PR #18: Added domain-specific maturity criteria to all 4 review domains
- PR #19: Rewrote as universal Hygiene gate (Irreversible/Total/Regulated) with outcome-based levels. Removed technique names from criteria.

**Key design decision (PR #19):** The Hygiene gate uses consequence-severity tests, not domain-specific checklists. This ensures the same escalation logic across Architecture, SRE, Security, and Data domains.

## Books and Publications

### Domain-Driven Design

**Author:** Eric Evans
**Published:** 2003, Addison-Wesley
**ISBN:** 978-0321125217
**Relevance:** Foundational source for bounded contexts, ubiquitous language, aggregates, value objects, domain events, anti-corruption layers, and context maps. The most heavily-referenced book across the Architecture domain — concepts appear at Code, Service, and Landscape zoom levels.
**Specific concepts referenced:**
- Bounded Context (Service, Landscape)
- Ubiquitous Language (Code, Service)
- Aggregate (Code)
- Value Object (Code)
- Entity (Code)
- Domain Event (Code, Landscape)
- Anti-Corruption Layer (Service, System, Landscape)
- Context Map (Landscape)
- Published Language (Landscape)
- Customer-Supplier, Conformist, Partnership relationships (Landscape)

### Modern Software Engineering

**Author:** Dave Farley
**Published:** 2021, Addison-Wesley
**ISBN:** 978-0137314911
**Relevance:** Provides the testability and deployability lens applied at all zoom levels. Key principle: complexity is the root cause of most software failures; testability and deployability are the primary tools for managing it.
**Specific concepts referenced:**
- Testability as a design driver (Code, Service)
- Independent deployability (Service)
- Managing complexity through modularity (Code, Service)
- Verification at multiple levels — unit, integration, acceptance (Code)
- Cyclomatic complexity management (Code)

### Release It! (2nd Edition)

**Author:** Michael T. Nygard
**Published:** 2018, Pragmatic Bookshelf
**ISBN:** 978-1680502398
**Relevance:** Provides the stability patterns and anti-patterns applied at the System zoom level. The famous quote "Integration points are the number-one killer of systems" drives the System level's focus on protected integration points.
**Specific patterns referenced:**
- Circuit Breaker (System — Chapter 5)
- Bulkhead (System — Chapter 5)
- Timeout (System — Chapter 5)
- Shed Load (System — Chapter 5)
- Backpressure (System — Chapter 5)
- Fail Fast (System — Chapter 5)
- Governor (System — Chapter 5)
- Dogpile / Thundering Herd (System — Chapter 5)
- Integration Point as the #1 killer (System — Chapter 4)
- Cascading Failures (System — Chapter 4)

### Enterprise Integration Patterns

**Authors:** Gregor Hohpe, Bobby Woolf
**Published:** 2003, Addison-Wesley
**ISBN:** 978-0321200686
**Relevance:** Provides the integration pattern vocabulary applied at the Landscape zoom level and partially at the System level. The catalogue of messaging patterns (channels, routers, transformers) informs the Landscape checklist.
**Specific patterns referenced:**
- Message Channel (Landscape)
- Message Router / Content-Based Router (Landscape)
- Message Transformer (Landscape)
- Dead Letter Channel (Landscape)
- Idempotent Consumer (Landscape, System)
- Message Design: Commands, Events, Documents (Landscape)
- Splitter/Aggregator (Landscape)
- Integration Styles: File Transfer, Shared Database, RPC, Messaging (Landscape)

### Clean Architecture

**Author:** Robert C. Martin
**Published:** 2017, Prentice Hall
**ISBN:** 978-0134494166
**Relevance:** Provides the dependency rule and layering concepts applied at the Service zoom level. The core principle: dependencies should point inward — outer layers depend on inner layers, never the reverse.
**Specific concepts referenced:**
- Dependency Rule (Service)
- Ports & Adapters / Hexagonal Architecture (Service)
- Use Cases / Application layer (Service)
- Entities / Domain layer (Service)

### Building Evolutionary Architectures

**Authors:** Neal Ford, Rebecca Parsons, Patrick Kua
**Published:** 2017, O'Reilly Media
**ISBN:** 978-1491986363
**Relevance:** Provides the fitness function and evolutionary architecture concepts applied at the Landscape zoom level.
**Specific concepts referenced:**
- Fitness Functions (Landscape)
- Evolutionary Architecture (Landscape)
- Incremental Change (Landscape, L3 criteria)

## Standards and Conventions

### Postel's Law (Robustness Principle)

**Origin:** Jon Postel, RFC 761 (1980)
**Statement:** "Be conservative in what you send, be liberal in what you accept."
**Relevance:** Applied at the System zoom level for API backward compatibility and the Tolerant Reader pattern. Services should tolerate unknown fields and unexpected values from peers.

### Architecture Decision Records (ADRs)

**Origin:** Michael Nygard, blog post "Documenting Architecture Decisions" (2011)
**Extended by:** Joel Parker Henderson (ADR GitHub organisation), Andrew Harmel-Law
**Relevance:** Applied at the Landscape zoom level. ADRs are the standard format for documenting architectural decisions with context, decision, and consequences.
**Template:** Context → Decision → Consequences → Status (Proposed/Accepted/Deprecated/Superseded)

### The Twelve-Factor App

**URL:** https://12factor.net/
**Relevance:** Informs the Service zoom level's deployability checklist, particularly:
- Factor III: Config (externalized configuration)
- Factor IV: Backing services (treat as attached resources)
- Factor VI: Processes (stateless processes)
- Factor X: Dev/prod parity

## Project History

Key PRs that shaped the Architecture domain, in chronological order:

| PR | What changed | Design impact |
|----|-------------|---------------|
| #7 | Initial Architecture review system | Established C4-inspired zoom levels, 4 subagents, prompt structure. Named "Landscape" not "Enterprise". All agents use sonnet model. |
| #18 | Cascading maturity model added | Domain-specific maturity criteria (HYG/L1/L2/L3) in `_base.md` and `SKILL.md` |
| #19 | Universal Hygiene gate, outcome-based levels | Removed technique names from criteria. Hygiene uses consequence-severity tests. Architecture criteria rewritten as observable outcomes. |
| #21 | Batch orchestrator `/review-all` | Architecture runs as one of 4 parallel domains (ARC), results in `arc.md` sub-report |
| #23 | Namespace attempt (closed, not merged) | Skill namespacing via subdirectories didn't work as expected. Led to plugin-based distribution approach (`donkey-dev/`). |

## Design Decisions

### Why "Landscape" not "Enterprise" (PR #7)

"Enterprise" carries baggage — implies large organisations, heavy governance, ivory tower architecture. "Landscape" is neutral and descriptive — it describes the view (looking at the ecosystem) rather than the organisation type. A startup with 3 services has a landscape too.

### Why all sonnet models (PR #7)

Unlike SRE (where the Delivery pillar uses haiku for more binary assessments) or Security (where audit-resilience uses haiku), all 4 Architecture agents use sonnet. Architecture review at every level requires interpreting code structure against design principles — a fundamentally interpretive task. There's no "binary checklist" level in architecture.

### Why outcome-based criteria (PR #19)

Technique names in criteria create false negatives. "Uses DDD" excludes teams that achieve bounded contexts through other means. "Implements Clean Architecture" excludes teams that follow the dependency rule using hexagonal architecture or simply good judgement. Outcome-based criteria ("Module boundaries are explicit", "Dependencies flow inward") are technology-neutral and verifiable from code.
