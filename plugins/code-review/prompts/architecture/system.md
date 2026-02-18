# System

Do services work well together?

The System zoom level evaluates whether the services in a changeset interact safely and without hidden coupling.
It examines whether integration points are protected from failure, data exchanges are bounded and explicit, and service communication uses styles appropriate to the relationship.
When this zoom level is weak, a slow downstream service can stall all callers, an unbounded query can exhaust memory under normal growth, and a schema change can silently break consumers that nobody knew existed.

**Note for single-service monoliths:** If the changeset touches only one deployable service with no inter-service calls, this zoom level may return no findings.
That is a correct and expected output — not a gap.
Do not fabricate System-level findings for a codebase that has no inter-service interactions.

## Focus Areas

### Design Principles focus (what should this look like?)

- **Integration point protection** — Every call to an external service should have an explicit timeout and structural isolation so that failure of the remote service cannot block unrelated functionality.
  A caller that can be indefinitely stalled by a downstream dependency passes its outage on to its own callers.
- **Failure containment** — Failure in one integration point should not propagate to unrelated parts of the system.
  Services should degrade gracefully when a dependency is unavailable, rather than failing entirely.
- **Bounded data exchange** — Every cross-service data exchange should be bounded by pagination, a result limit, or streaming.
  Queries that can return an unlimited number of records become memory and latency hazards as data grows.
- **Explicit communication contracts** — Services should interact through formal, versioned contracts.
  Breaking changes should be detectable before they reach production, not discovered when a client crashes at runtime.
- **Communication style alignment** — The choice between synchronous and asynchronous communication should match the nature of the interaction.
  Synchronous calls couple the caller's availability to the callee's; asynchronous messaging decouples them.

### Erosion Patterns focus (how does this go wrong?)

- **Unprotected integration points** — External calls with no timeout and no failure isolation.
  One slow dependency stalls all callers; all callers stall their callers.
- **Cascading failure paths** — Synchronous call chains where failure in any participant propagates to every upstream caller without isolation between steps.
- **Unbounded result sets** — Cross-service queries that can return millions of records with no pagination or limit.
  Memory exhaustion arrives gradually, with no single event to trigger an alert.
- **Shared data stores** — Multiple services accessing the same database tables.
  Schema changes break unknown consumers; data ownership becomes ambiguous.
- **Temporal coupling** — Implicit ordering requirements between service calls not enforced by the API.
  Out-of-order calls produce silent data corruption rather than an explicit error.
- **Missing contracts** — Services communicating without a formal definition of the exchange.
  Breaking changes are discovered at runtime, in production.

## Anti-Pattern Catalogue

### YL-01: Unprotected integration point

```python
# BAD: No timeout, no failure isolation
response = requests.get(f"http://downstream/api/data")
```

**Why it matters:** A slow or failing downstream service holds the calling thread open indefinitely.
Under failure, all available threads can be consumed waiting, making the calling service entirely unresponsive to its own callers.
Erosion pattern: Unprotected integration points, Tight coupling.
Typical severity: HIGH / HYG (Total — a single slow dependency can exhaust all caller threads).

### YL-02: Cascading failure path

A synchronous call chain A → B → C → D with no failure isolation between steps.

**Why it matters:** A failure in D propagates to C, then B, then A, because no step can absorb the failure independently.
The entire chain goes down together even when only one participant is unhealthy.
Erosion pattern: Cascading failure paths, Tight coupling.
Typical severity: HIGH / HYG (Total — one failing service brings down all upstream callers in the chain).

### YL-03: Unbounded result sets

```python
# BAD: Could return millions of records
orders = order_service.get_all_orders()
```

**Why it matters:** The query works correctly when data is small.
As the dataset grows, the response size grows with it, eventually exhausting caller memory or exceeding request timeouts under normal operating conditions.
Erosion pattern: Unbounded data exchange, Implicit contracts.
Typical severity: HIGH / L1.

### YL-04: Shared database across services

Multiple services reading from or writing to the same database tables.

**Why it matters:** A schema migration made for one service silently breaks all other services that access the same tables.
Data ownership is ambiguous — two services can write conflicting state to the same rows.
Independent deployment becomes impossible: any database change requires coordinating all consumers simultaneously.
Erosion pattern: Tight coupling, Implicit contracts.
Typical severity: HIGH / HYG (Irreversible — shared tables create data corruption risk; Total — one migration can break all consumers simultaneously).

### YL-05: Temporal coupling

Service A must call B before C; out-of-order calls succeed at the API level but produce silent data corruption.

**Why it matters:** The ordering requirement is not expressed in the API — it exists only as undocumented knowledge.
Callers that are unaware of the requirement produce corrupt state without receiving an error.
The corruption may not be detected until well after the transaction completes.
Erosion pattern: Implicit contracts, Temporal coupling.
Typical severity: MEDIUM / L2.

### YL-06: Missing contract

Services exchange data with no formal contract definition — no OpenAPI specification, no Protobuf schema, no AsyncAPI document, or equivalent.

**Why it matters:** There is no machine-readable definition of what is expected or what is guaranteed.
A producer can change a field name, remove a field, or alter a type, and the consumer will not discover the incompatibility until it processes a response at runtime.
Erosion pattern: Implicit contracts, Tight coupling.
Typical severity: MEDIUM / L1.

## Review Checklist

When assessing the System zoom level, work through each item in order.

1. **Integration point protection** — Do all calls to external services have explicit timeouts?
   Is there structural isolation so that a failing dependency does not block unrelated functionality?
2. **Failure propagation** — Does failure in one service cascade to unrelated services?
   Are there synchronous call chains with no failure isolation between each step?
3. **Result set bounds** — Are all cross-service queries bounded by pagination, limits, or streaming?
   Can any endpoint return an unbounded number of records?
4. **Data ownership** — Does each service own its own data store?
   Are there database tables accessed by more than one service (read or write)?
5. **Communication contracts** — Are all service integration points defined by a formal contract?
   Can a breaking API change be detected before it reaches production?
6. **Ordering assumptions** — Are there implicit ordering requirements between service calls that are not enforced by the API design?
   Can out-of-order calls succeed at the API level while producing incorrect state?

## Severity Framing

Severity for System findings is about structural consequence — how widely failure or a breaking change can spread across the system.

- **Unprotected integration points and cascading failure paths** — A slow dependency takes down the caller, and the caller takes down its callers.
  These are Hygiene findings because the blast radius is the entire call chain.
  Typically HIGH / HYG (Total).
- **Shared database across services** — Schema changes cascade to all consumers without any API change to signal the risk.
  Typically HIGH / HYG (Irreversible + Total).
- **Unbounded result sets** — Memory exhaustion under normal data growth, with no single trigger event.
  Typically HIGH / L1.
- **Missing contracts** — Breaking changes discovered in production rather than at build or deploy time.
  Typically MEDIUM / L1.
- **Temporal coupling** — Silent data corruption from out-of-order calls; the API does not protect callers from the hazard.
  Typically MEDIUM / L2.
- **Single-service monoliths** — For codebases with no inter-service interactions, System-level findings do not apply.
  "No findings at this zoom level" is a valid and correct output.
