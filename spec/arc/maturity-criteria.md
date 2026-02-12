# Maturity Criteria — Architecture Domain

> Detailed criteria for each maturity level with defined "sufficient" thresholds. Use this when assessing criteria as Met / Not met / Partially met.

## Hygiene Gate

The Hygiene gate is not a maturity level — it is a promotion gate. Any finding at any level that passes any of the three tests is promoted to `HYG`.

### Test 1: Irreversible

**Question:** If this goes wrong, can the damage be undone?

**Threshold:** If a structural flaw would produce damage that requires more than a rollback/restart to fix — e.g., corrupted data across service boundaries, merged data that can't be unmerged, shared state that multiple services have written to inconsistently — this is irreversible.

**Architecture examples that trigger this test:**
- Two services writing directly to the same database tables — data corruption from conflicting writes can't be unwound without understanding both services' write patterns
- Circular dependency between modules that has been accumulated over months — extracting it requires rewriting both modules and all their consumers
- Schema changes deployed to a shared database that other services depend on — rolled-back code still encounters the new schema

**Architecture examples that do NOT trigger this test:**
- Missing abstraction layer (bad design but fixable without data risk)
- Inconsistent naming (confusing but not damaging)
- Missing ADRs (knowledge gap but no corruption)

### Test 2: Total

**Question:** Can this take down the entire service or cascade beyond its boundary?

**Threshold:** If a structural flaw can cause one component's failure to propagate beyond its boundary — taking down the entire service, blocking all deployments, or cascading to other services — this is total.

**Architecture examples that trigger this test:**
- Synchronous circular dependency chain where one service's failure cascades to all participants in the cycle
- Deployment coupling — all services must be deployed simultaneously, so one deployment failure blocks all
- Shared database across services — one service's migration breaks all consumers
- Distributed monolith — services that can't function independently, so one outage brings down all

**Architecture examples that do NOT trigger this test:**
- A God class within a single service (contained to one deployment unit)
- Missing bounded context boundary (poor cohesion but failures are contained)
- Anemic domain model (bad design but doesn't cause cascading failure)

### Test 3: Regulated

**Question:** Does this violate a legal or compliance obligation?

**Threshold:** If the architectural design would cause a breach of data protection law, financial regulation, accessibility requirements, or other legal obligations, this is regulated.

**Architecture examples that trigger this test:**
- PII leaking through a missing Anti-Corruption Layer into a public API response
- Data residency requirements violated by architectural boundary placement (e.g., EU user data processed by a US-only service)
- Financial calculation logic using floating-point arithmetic for money (regulatory accuracy requirements)

**Architecture examples that do NOT trigger this test:**
- Missing ADRs (governance gap, not regulatory)
- No fitness functions (quality gap, not compliance)
- Inconsistent API styles across services (style issue, not regulatory)

---

## Level 1 — Foundations

**Overall intent:** The basics are in place. The system has clear structure and can be understood and tested. A new developer can find module boundaries and understand dependencies.

### Criterion 1.1: Module boundaries are explicit with defined public interfaces

**Definition:** Modules, packages, or services have clear boundaries with intentional public APIs. Internal implementation details are not exposed to consumers.

**Met (sufficient):**
- Modules have defined public interfaces (exports, public methods, API contracts)
- Internal implementation details are not accessible from outside the module
- It is clear from the code structure which parts are public and which are internal
- New functionality has a clear "home" — you know which module it belongs to

**Partially met:**
- Some modules have clear boundaries, others are loosely defined
- Public interfaces exist but internal details leak (e.g., domain objects expose ORM annotations)
- Module boundaries are implicit (based on convention, not enforced)

**Not met:**
- No clear module boundaries — classes and functions are organised by technical layer only (all controllers together, all models together)
- Everything is public — any module can import anything from any other module
- Module placement is arbitrary — similar concepts live in different modules

### Criterion 1.2: Dependencies flow inward

**Definition:** Infrastructure (database, HTTP, filesystem) depends on the domain — not the reverse. Business logic does not import infrastructure frameworks.

**Met (sufficient):**
- Domain/business logic has no imports from infrastructure frameworks (ORM, HTTP, messaging)
- Infrastructure code implements interfaces defined in the domain layer
- The dependency graph shows: infrastructure → application → domain (never domain → infrastructure)
- Changing the database or HTTP framework would not require modifying domain logic

**Partially met:**
- Most domain logic is infrastructure-free, but some domain objects have ORM annotations or HTTP concerns
- The general direction is correct but there are exceptions (some domain classes import utility functions from infrastructure packages)

**Not met:**
- Domain classes inherit from ORM base classes or use ORM annotations
- Business logic directly calls database queries, HTTP endpoints, or filesystem operations
- No distinction between domain and infrastructure layers

### Criterion 1.3: Components can be tested in isolation

**Definition:** Business logic can be unit tested without standing up infrastructure (database, network, filesystem, message broker).

**Met (sufficient):**
- Dependencies are injectable (constructor injection, parameter injection)
- Side effects are isolated behind interfaces that can be substituted in tests
- Unit tests exist that verify business logic without infrastructure
- Test files exist alongside or near the code they test

**Partially met:**
- Some components are testable in isolation, others require infrastructure
- Dependencies are injectable but no tests exercise this capability
- Tests exist but all require a running database or service

**Not met:**
- Dependencies are constructed internally (hidden dependencies)
- Business logic can only be tested through integration tests
- No tests exist, or tests only verify infrastructure wiring

### Criterion 1.4: No circular dependencies between modules

**Definition:** The dependency graph between modules/packages is a directed acyclic graph (DAG). No module depends on another module that depends back on it (directly or transitively).

**Met (sufficient):**
- No circular imports between modules or packages
- The dependency graph is a clean tree or DAG
- Module dependencies are explicitly declared (imports, package references)

**Partially met:**
- No direct circular dependencies, but transitive cycles exist through shared modules
- Circular dependencies exist but are contained within a single bounded context

**Not met:**
- Direct circular dependencies between modules (A imports B, B imports A)
- Circular dependency chains spanning multiple modules
- Import order matters (fragile initialisation)

---

## Level 2 — Hardening

**Overall intent:** Architecturally mature. The system has explicit contracts, documented design rationale, and failure containment at integration boundaries. Teams can reason about the system's design without reading all the code.

**Prerequisite:** All L1 criteria must be met.

### Criterion 2.1: Integration contracts are defined between boundaries

**Definition:** Services and modules that communicate have explicit, versioned contracts — not just "it calls that endpoint."

**Met (sufficient):**
- API contracts exist (OpenAPI, Protobuf, GraphQL schema, AsyncAPI, or equivalent)
- Contracts are stored in version control
- Contracts distinguish between stable/public interfaces and internal/unstable ones
- Breaking changes are detectable (contract tests, schema validation, or equivalent)

**Partially met:**
- Some contracts are formal, others are implicit (known only through code inspection)
- Contracts exist but aren't versioned or tested
- Contracts exist but don't cover all integration points

**Not met:**
- No formal contracts — integration is through code inspection and tribal knowledge
- Contract changes are discovered at runtime (production errors)
- No distinction between public/stable and internal/experimental APIs

### Criterion 2.2: Design decisions are documented with rationale and trade-offs

**Definition:** Significant architectural decisions are recorded in a retrievable format — ADRs, design docs, tech-specs, or equivalent — including the why, not just the what.

**Met (sufficient):**
- ADRs or equivalent exist for major technology choices (language, framework, database, messaging)
- Each record includes context (why the decision was needed), decision (what was chosen), and consequences (trade-offs accepted)
- Records are stored in version control alongside the code
- Records are current — recent decisions are documented, not just historical ones

**Partially met:**
- Some decisions are documented but major ones are missing
- Documentation exists but lacks rationale ("we chose PostgreSQL" without explaining why)
- Records exist but are stale — the system has evolved beyond what's documented

**Not met:**
- No architectural decision documentation
- Decisions exist only in people's heads or buried in Slack/email threads
- A tech-spec exists but hasn't been updated in more than 6 months and doesn't match the code

### Criterion 2.3: Failure at integration points is contained, not propagated

**Definition:** When an external dependency fails, the failure does not cascade to unrelated functionality. Some form of structural isolation exists at the design level.

**Met (sufficient):**
- Integration points have explicit failure handling (not just catch-all exception handlers)
- Non-critical dependencies are structurally separated from critical paths (different modules, different call paths)
- The design includes degradation options — reduced functionality rather than total failure
- Failure domains are intentional and documented

**Partially met:**
- Some integration points have failure isolation, others don't
- Failure handling exists but all failures are treated the same (no critical vs non-critical distinction)
- Degradation exists by accident (catch blocks that return null) rather than by design

**Not met:**
- No structural failure isolation — all dependencies are called in the same code path
- One dependency failure causes the entire service to fail
- No distinction between critical and non-critical dependencies in the code structure

### Criterion 2.4: Bounded contexts are explicit and internally consistent

**Definition:** Services or modules aligned to domain concepts have internally consistent models that don't leak across boundaries.

**Met (sufficient):**
- Each service or major module serves a single cohesive domain concept
- Domain terminology is consistent within each context (ubiquitous language)
- Cross-context communication uses explicit translation (ACLs, mapping layers)
- External models are not used directly in domain logic

**Partially met:**
- Most services have clear domain alignment, but some serve multiple contexts
- Translation layers exist at some boundaries but not all
- Domain terminology is mostly consistent but has some confusing overlap

**Not met:**
- Services serve multiple unrelated domain concepts
- External DTOs are used throughout domain logic
- The same term means different things in different parts of the codebase with no explicit mapping

---

## Level 3 — Excellence

**Overall intent:** Best-in-class. Architecture is actively governed, constraints are validated automatically, and the system can evolve incrementally without coordinated deployment.

**Prerequisite:** All L2 criteria must be met.

### Criterion 3.1: Architectural constraints are validated automatically in CI

**Definition:** Fitness functions or equivalent automated tests verify that architectural rules are preserved across changes.

**Met (sufficient):**
- Automated tests enforce dependency direction (no domain → infrastructure imports)
- Circular dependency detection runs in CI
- API compatibility checks detect breaking changes before merge
- At least one fitness function exists for a non-trivial architectural characteristic

**Partially met:**
- Some architectural tests exist but don't cover the most important constraints
- Tests exist but run manually, not in CI
- Dependency checks exist but only at the package level, not the module level

**Not met:**
- No automated architectural tests
- Architectural rules exist on paper but are not enforced
- CI runs only functional tests, no structural validation

### Criterion 3.2: Cross-boundary relationships are documented and kept current

**Definition:** A context map or equivalent documentation shows how bounded contexts relate, with explicit relationship types (partnership, customer-supplier, conformist, ACL, etc.).

**Met (sufficient):**
- A context map (visual or structured) exists showing all bounded contexts and their relationships
- Relationship types are explicit (not just "A calls B" but "A is a customer-supplier to B")
- The map is maintained — it reflects the current state of the system, not a historical snapshot
- Changes to cross-boundary relationships trigger documentation updates

**Partially met:**
- A context map exists but is stale or incomplete
- Relationships are documented but types are implicit
- Some cross-boundary relationships are documented, others are not

**Not met:**
- No context map exists
- Cross-boundary relationships are discovered only through code inspection
- Documentation exists but describes a previous version of the system

### Criterion 3.3: Changes can be made incrementally without coordinated deployment

**Definition:** Services can be deployed independently. Breaking changes use incremental strategies (expand-contract, strangler fig, feature flags).

**Met (sufficient):**
- Services can be deployed in any order without coordination
- Breaking changes follow expand-contract (add new, migrate, remove old)
- Feature flags or equivalent exist for significant behaviour changes
- Database migrations are backward-compatible (add-before-remove)

**Partially met:**
- Most services deploy independently but some still require coordination
- Expand-contract is used sometimes but not consistently
- Feature flags exist for some features but not standard practice

**Not met:**
- Deployment requires coordinating multiple services
- Breaking changes are deployed directly
- Database migrations require downtime or break backward compatibility

### Criterion 3.4: Evolution strategy exists for major changes

**Definition:** The team has patterns and infrastructure for managing large-scale architectural evolution without big-bang rewrites.

**Met (sufficient):**
- Migration patterns are documented and used (strangler fig, parallel run, branch by abstraction)
- Technology choices are deliberate and documented (technology radar, ADRs for new adoptions)
- Deprecation process exists — old interfaces are sunset with timelines and migration guides
- The number of technologies solving the same problem is bounded (not 3 different messaging systems)

**Partially met:**
- Some migration patterns are used ad hoc but no standard approach exists
- Technology choices are mostly deliberate but some are inherited and undocumented
- Deprecation happens but without formal timelines or consumer communication

**Not met:**
- No migration patterns — changes are big-bang rewrites
- Technology choices are ad hoc — new technologies adopted without evaluation
- No deprecation process — old interfaces persist indefinitely alongside new ones
