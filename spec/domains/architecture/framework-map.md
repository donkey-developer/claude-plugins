# Framework Map — Zoom Levels, Frameworks, and Principles

> How the Architecture domain's frameworks relate to each other. Use this map when writing or reviewing prompts to ensure coverage is complete and analytical lenses are applied correctly.

## The Duality: Principles guide, Erosion threatens

Every design principle has a corresponding erosion pattern — the way architecture degrades when the principle is neglected. When a reviewer identifies an erosion pattern, they should recommend strengthening the corresponding principle.

| Design Principle | Erosion Pattern | Effect of erosion | Where most visible |
|------------------|----------------|-------------------|-------------------|
| **Separation of Concerns** | **Mixed responsibilities** | Changes require touching unrelated code. Components grow unbounded. Testing requires standing up the world. | Code (God class), Service (domain logic in controllers) |
| **Loose Coupling** | **Tight coupling** | Independent deployment impossible. One change ripples across many modules. Circular dependencies prevent extraction. | Code (circular deps), System (shared database), Landscape (coordinated deployments) |
| **High Cohesion** | **Scattered behaviour** | Related logic spread across modules. Shotgun surgery — one logical change touches many files. Feature envy. | Code (feature envy), Service (service too broad) |
| **Testability** | **Hidden dependencies** | Can't unit test without infrastructure. Side effects embedded in business logic. Constructor does too much. | Code (untestable code), Service (infrastructure in domain) |
| **Explicit over Implicit** | **Magic and indirection** | Contracts undocumented. Dependencies invisible. Assumptions buried in code. Newcomers can't understand the system. | Service (missing ACL), System (missing contracts), Landscape (undocumented integration) |

### Using the duality in reviews

When writing a finding:
1. Identify the **erosion pattern** (how the architecture is degrading)
2. Check the **design principle** being violated
3. If the principle is absent or insufficient, that's the finding
4. The recommendation should describe the principle to strengthen, not a specific technique

Example:
- Erosion: Tight coupling (Service A imports Service B's internal models)
- Principle needed: Loose coupling (depend on published contracts, not internals)
- Finding: "Service A directly imports Service B's database models, creating deployment coupling"
- Recommendation: "Introduce a translation boundary — consume Service B's published API contract rather than its internal models"

## Zoom Level Framework Sources

Each zoom level draws its analytical lens from specific framework sources. This is not exclusive — any framework insight can appear at any level — but these are the primary sources each subagent should apply.

### Code Level

**Primary question:** Is the code well-structured?

| Framework | What it provides | How it's applied |
|-----------|-----------------|-----------------|
| **SOLID** (Martin) | Five principles for class/module design | Review checklist: SRP, OCP, LSP, ISP, DIP |
| **DDD Tactical** (Evans) | Patterns for modelling domain concepts | Review checklist: Entities, Value Objects, Aggregates, Repositories, Domain Events |
| **Modern SE** (Farley) | Complexity management through testability | Review checklist: testability, cyclomatic complexity, cohesion, coupling, naming |

### Service Level

**Primary question:** Is the service well-designed?

| Framework | What it provides | How it's applied |
|-----------|-----------------|-----------------|
| **DDD Strategic** (Evans) | Bounded contexts, model integrity, translation | Review checklist: context boundary, ubiquitous language, model integrity, ACLs |
| **Clean Architecture** (Martin) | Dependency rule, layering, ports & adapters | Review checklist: dependency direction, separation of concerns, CQRS |
| **Modern SE** (Farley) | Independent deployability, configuration | Review checklist: deployment independence, health checks, graceful lifecycle |

### System Level

**Primary question:** Do services work well together?

| Framework | What it provides | How it's applied |
|-----------|-----------------|-----------------|
| **Release It!** (Nygard) | Stability patterns and anti-patterns | Review checklist: circuit breaker, bulkhead, timeout, shed load, backpressure, fail fast, governor |
| **EIP** (Hohpe & Woolf) | Communication style selection | Review checklist: sync vs async, event vs command, idempotency |
| **Postel's Law** | Tolerant communication | Review checklist: backward compatibility, tolerant reader |

### Landscape Level

**Primary question:** Does it fit the wider ecosystem?

| Framework | What it provides | How it's applied |
|-----------|-----------------|-----------------|
| **EIP** (Hohpe & Woolf) | Integration patterns for distributed systems | Review checklist: message design, routing, transformation, dead letters, idempotent consumers |
| **DDD Context Maps** (Evans) | Cross-boundary relationship types | Review checklist: context map, relationship types (partnership, customer-supplier, conformist, ACL, open host, published language) |
| **ADR Pattern** (Nygard, Keeling) | Decision documentation | Review checklist: ADRs, tech-spec traceability, decision freshness |
| **Evolutionary Architecture** (Ford, Parsons, Kua) | Fitness functions, incremental change | Review checklist: fitness functions, backward compatibility, deprecation, migration |

## Coverage Matrix

This matrix shows which design principles are the primary concern at each zoom level. Use it to verify that prompt changes don't create coverage gaps.

| | Separation of Concerns | Loose Coupling | High Cohesion | Testability | Explicit over Implicit |
|---|---|---|---|---|---|
| **Code** | Primary | Primary | Primary | Primary | Secondary |
| **Service** | Primary | Primary | Secondary | Primary | Primary |
| **System** | Secondary | Primary | - | - | Primary |
| **Landscape** | - | Primary | - | - | Primary |

**Key:** Primary = core focus area for this zoom level. Secondary = reviewed but not the primary lens. `-` = not a focus area (may still be flagged if found).

## Framework-to-Zoom-Level Coverage Matrix

This matrix shows which frameworks are the primary analytical lens at each zoom level.

| | SOLID | DDD Tactical | DDD Strategic | Release It! | EIP | Modern SE | ADR/Governance |
|---|---|---|---|---|---|---|---|
| **Code** | Primary | Primary | - | - | - | Primary | - |
| **Service** | - | Secondary | Primary | - | - | Primary | - |
| **System** | - | - | Secondary | Primary | Secondary | - | - |
| **Landscape** | - | - | Primary | - | Primary | - | Primary |

**Key:** Primary = core analytical lens for this level. Secondary = relevant but not the primary focus. `-` = not applicable at this level.

## Inter-Level Handoffs

When a finding spans zoom levels, the subagent that discovers it should flag it in their own level's terms. The synthesis step deduplicates across levels.

Common handoff scenarios:

| Scenario | Discovered by | Also relevant to |
|----------|---------------|------------------|
| A class violates SRP AND the service has mixed bounded contexts | Code (God class) | Service (service too broad) |
| A service depends on another's internals AND there's no contract | Service (missing ACL) | System (data coupling) |
| Circular dependency between classes creates deployment coupling | Code (circular deps) | System (cascading failure risk) |
| Shared database at code level AND no API boundary at system level | Service (shared database) | System + Landscape (integration point) |
| Missing error model design AND missing error classification | Service (error hierarchy) | System (inconsistent error responses) |
| Domain logic in controllers AND missing testability | Code (testability) | Service (domain logic in controllers) |

## Boundary with Other Domains

The Architecture domain focuses on **design-time structure**. When a finding could belong to multiple domains, use this boundary guide:

| Finding type | Architecture owns | Other domain owns |
|-------------|-------------------|-------------------|
| Circuit breaker | "Is this the right pattern for this integration point?" | SRE: "Is it configured with correct thresholds and monitored?" |
| Error handling | "Is the error model well-designed? (hierarchy, classification, propagation)" | SRE: "Can operators diagnose from errors at 3am?" |
| Coupling | "Is the dependency structurally appropriate?" | SRE: "Does it cause cascading failure at runtime?" |
| Deployability | "Is it independently deployable by design?" | SRE: "Can it be safely rolled out with rollback?" |
| Data model | "Are bounded contexts correctly separated?" | Data: "Are schema contracts defined and quality monitored?" |
| Access control | "Is the authorization model well-designed?" | Security: "Can an attacker bypass the authorization checks?" |
