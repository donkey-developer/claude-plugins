# Service

Is the service well-designed?

The Service zoom level evaluates whether a deployable unit serves a single cohesive domain concept, can be changed and deployed independently, and keeps business logic separate from infrastructure concerns.
When this zoom level is weak, services grow without bound, deployments require coordination across teams, and changes in one service silently break another.

## Focus Areas

### Design Principles focus (what should this look like?)

- **Domain coherence** — A service should serve one cohesive domain concept.
  You should be able to describe what the service does without using "and" to connect unrelated concerns.
- **Dependency direction** — Business logic should have no imports from infrastructure frameworks.
  Infrastructure (databases, HTTP, messaging) depends on the domain, not the reverse.
- **Deployment independence** — A service should be deployable without coordinating with other services.
  Each service owns its own data store; no shared schema crosses service boundaries.
- **Explicit interface** — The service boundary is a coarse-grained, versioned contract.
  External systems interact through the interface, not through shared internal state.
- **External model isolation** — Models from upstream systems are translated at the boundary.
  The domain structure is determined by domain needs, not by whatever the upstream system happens to produce.

### Erosion Patterns focus (how does this go wrong?)

- **Shared database** — Two services read or write the same database tables.
  Invisible coupling makes independent deployment and schema evolution impossible.
- **Distributed monolith** — Services must be deployed together.
  Shared libraries carry domain logic across service boundaries; one call chain requires all participants to be running simultaneously.
- **Domain logic in infrastructure** — Business rules live in HTTP handlers, queue consumers, or persistence adapters.
  The logic cannot be tested without the infrastructure it is embedded in.
- **Service too broad** — A single service serves multiple unrelated domain concepts with different change cadences and different stakeholders.
  It will grow without bound and resist decomposition.
- **Upstream model leakage** — External DTOs or upstream API responses are used directly in domain logic.
  The upstream model now dictates the downstream domain structure.
- **Flat error model** — All errors are treated the same.
  Callers cannot distinguish between a transient failure they should retry and a permanent failure they should not.

## Anti-Pattern Catalogue

### SL-01: Shared database

Two services reading from or writing to the same database tables.

**Why it matters:** Schema changes made for one service break the other without any API change.
Deployment of either service must be coordinated with the other.
Data ownership is ambiguous — two services can write conflicting state to the same rows.
Erosion pattern: Tight coupling across service boundaries.
Typical severity: HIGH / HYG (Irreversible — shared tables create data corruption risk across service boundaries; Total — one migration can break all consumers simultaneously).

### SL-02: Distributed monolith

Services that must be deployed together.
Shared libraries containing domain logic.
Synchronous call chains where all participants must be running for any to succeed.

**Why it matters:** The organisational benefits of separate services (independent teams, independent deployments, isolated failure) are absent.
The operational costs of distributed systems (network latency, partial failure, distributed tracing) remain.
Erosion pattern: Tight coupling.
Typical severity: HIGH / HYG (Total — one deployment failure or network partition cascades to all participants in the chain).

### SL-03: Domain logic in controllers

```python
@app.route("/orders", methods=["POST"])
def create_order():
    if request.json["total"] > 1000:
        request.json["total"] *= 0.9  # domain logic in HTTP handler
    db.session.add(Order(**request.json))
```

**Why it matters:** Business rules are not testable without an HTTP framework and a running server.
Moving to a different transport (a queue consumer, a CLI, a scheduled job) requires finding and re-implementing scattered rules.
Erosion pattern: Hidden dependencies, Mixed responsibilities.
Typical severity: HIGH / L1.

### SL-04: Service too broad

A service described as "manages users AND handles billing AND sends notifications".
Different concerns with different change cadences, different stakeholders, and different operational profiles coexist in a single deployable.

**Why it matters:** Every deployment carries risk for all three concerns simultaneously.
Teams working on unrelated features contend for the same codebase and release cycle.
The service will grow without bound as new "and" concerns are added.
Erosion pattern: Mixed responsibilities.
Typical severity: MEDIUM / L1.

### SL-05: Missing anti-corruption layer

External DTOs or upstream API response models used directly inside domain logic, with no translation at the service boundary.

**Why it matters:** When the upstream system changes its model, the change propagates into domain logic unchanged.
The domain vocabulary is shaped by the upstream system rather than by the domain's own language.
Erosion pattern: Tight coupling, Implicit contracts.
Typical severity: MEDIUM / L1.

### SL-07: Missing error hierarchy

All errors propagated or logged identically, with no distinction between transient failures (timeout, rate limit), permanent failures (validation error, not found), and infrastructure failures (connection refused).

**Why it matters:** Callers cannot make correct retry decisions.
Retrying a permanent failure wastes resources and delays resolution.
Not retrying a transient failure produces unnecessary errors.
Erosion pattern: Mixed responsibilities, Implicit contracts.
Typical severity: MEDIUM / L1.

## Review Checklist

When assessing the Service zoom level, work through each item in order.

1. **Domain coherence** — Does the service serve a single cohesive domain concept?
   Can you describe what the service does without using "and" to connect unrelated concerns?
2. **Dependency direction** — Does business logic import infrastructure frameworks (databases, HTTP, messaging)?
   Dependencies should flow toward the domain, not away from it.
3. **Deployment independence** — Can this service be deployed without coordinating with other services?
   Are there shared libraries containing domain logic that cross service boundaries?
4. **Database ownership** — Does each service own its own data store?
   Are there database tables accessed by more than one service?
5. **External model isolation** — Are external system models (third-party DTOs, upstream API responses) used directly in domain logic, or are they translated at the service boundary?
6. **Error model** — Does the service distinguish between transient errors (retry appropriate), permanent errors (do not retry), and infrastructure errors?
   Does each error type communicate the correct retry semantics to callers?

## Severity Framing

Severity for Service findings is about coupling consequence — how much harder will the system be to change and deploy independently if this ships.

- **Shared database and distributed monolith** — These are structural blockers.
  Changes by one team cascade to others without any API change.
  Typically HIGH or HYG.
- **Domain logic in infrastructure** — Business logic cannot be tested without infrastructure.
  Moving to a different transport requires finding and re-implementing scattered rules.
  Typically HIGH / L1.
- **Service too broad** — The service accumulates unrelated concerns and grows without bound.
  Decomposition becomes progressively harder with each addition.
  Typically MEDIUM / L1.
- **Missing anti-corruption layer** — Upstream models leak into domain logic.
  The cost appears when the upstream system changes its model.
  Typically MEDIUM / L1.
- **Missing error hierarchy** — Callers cannot make correct retry decisions.
  Permanent failures are retried; transient failures surface as unrecoverable errors.
  Typically MEDIUM / L1.
