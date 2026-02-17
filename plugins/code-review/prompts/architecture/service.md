## Service Level — Is the Service Well-Designed?

The Service level examines deployable units — APIs, workers, and standalone services.
It evaluates whether a service has clear boundaries, sound layering, and can evolve independently.

## Focus Areas

- **Bounded context alignment** — the service serves one cohesive domain concept.
  Flag services that span multiple unrelated concerns, serve different stakeholders, or change for unrelated reasons.
- **Layering** — domain logic is separated from infrastructure and transport.
  Business rules should not live in HTTP handlers, message consumers, or database access code.
- **Deployability** — the service can be deployed independently.
  No shared databases, no mandatory co-deployment with other services, no shared domain libraries.
- **API design** — public interfaces are cohesive and not chatty.
  A single logical operation should not require multiple round-trips; aggregate endpoints exist for common workflows.
- **Dependency direction** — infrastructure depends on domain, not the reverse.
  Domain logic does not import transport or persistence frameworks.
- **Error classification** — errors are categorised by type (transient, permanent, infrastructure).
  Callers can distinguish retriable failures from permanent ones without parsing messages.
- **Anti-corruption** — external models are translated at the boundary, not used throughout.
  Upstream DTOs and third-party schemas do not flow into domain code.
- **Service scope** — the service does not span multiple unrelated concerns.
  Different change cadences, different stakeholders, or unrelated data models suggest the service should be split.

## Anti-Patterns

### SL-01: Shared database

Two services read/write the same database tables.
Creates invisible coupling; independent deployment is impossible.

```python
# Service A
orders = db.query("SELECT * FROM orders WHERE status = 'pending'")

# Service B — same table, different service
db.execute("UPDATE orders SET analytics_flag = true WHERE id = %s", order_id)
```

**Principle:** Loose Coupling, Explicit over Implicit | **Severity:** HIGH / HYG

### SL-02: Distributed monolith

Services that must be deployed together.
Shared libraries containing domain logic.
Synchronous call chains where all services must be running for any to work.
**Principle:** Loose Coupling | **Severity:** HIGH / HYG

### SL-03: Domain logic in controllers

Business rules implemented in HTTP handlers, API controllers, or message handlers rather than in the domain layer.

```python
@app.route("/orders", methods=["POST"])
def create_order():
    if request.json["total"] > 1000:
        request.json["total"] *= 0.9  # discount logic in HTTP handler
    db.session.add(Order(**request.json))
```

**Principle:** Separation of Concerns, Testability | **Severity:** HIGH / L1

### SL-04: Service too broad

A single service serving multiple bounded contexts — unrelated features, different change cadences, different stakeholders.
**Principle:** Separation of Concerns, High Cohesion | **Severity:** MEDIUM / L1

### SL-05: Missing anti-corruption layer

External DTOs or upstream models used directly throughout domain code without translation at the boundary.
**Principle:** Loose Coupling, Explicit over Implicit | **Severity:** MEDIUM / L1

### SL-06: Chatty interface

A client needs 5+ API calls to complete one logical operation.
Fine-grained CRUD endpoints with no aggregate operations.
**Principle:** High Cohesion, Explicit over Implicit | **Severity:** MEDIUM / L2

### SL-07: Missing error hierarchy

All errors treated the same — no distinction between transient, permanent, and infrastructure errors.
**Principle:** Explicit over Implicit | **Severity:** MEDIUM / L1

### SL-08: Layer bypass

Some features follow layered architecture, others skip layers — inconsistent structure.
**Principle:** Separation of Concerns | **Severity:** LOW / L1

## Checklist

- [ ] Does the service serve one cohesive domain concept, or does it span unrelated concerns?
- [ ] Is domain logic separated from transport (HTTP, messaging) and infrastructure (database, filesystem)?
- [ ] Can the service be deployed independently of other services?
- [ ] Are external models translated at the boundary, or do upstream DTOs flow through domain code?
- [ ] Do errors distinguish transient failures from permanent failures from infrastructure failures?
- [ ] Is the public API cohesive, or does a single operation require multiple calls?
- [ ] Does the service share database tables with other services?
- [ ] Are all layers used consistently, or are some features bypassing the domain layer?
- [ ] Can business logic be tested without standing up the HTTP server or database?
- [ ] Is the dependency direction consistent — infrastructure depends on domain, not vice versa?

## Positive Indicators

- Service aligned to a single bounded context with internally consistent language.
- Clear separation between transport, application, and domain layers.
- Business logic testable through domain interfaces without infrastructure.
- External dependencies isolated behind anti-corruption layers.
