## System Level — Do Services Work Well Together?

The System level examines how multiple services interact — their integration points, data flow, failure isolation, and contracts.
It evaluates whether the system's inter-service architecture supports reliable independent operation.
For monolithic codebases this level may return no findings; that is correct, not a gap.

## Focus Areas

- **Integration point protection** — external calls have timeouts, failure isolation, and error handling.
  Flag raw HTTP/gRPC calls with no protection against slow or failing dependencies.
- **Cascading failure isolation** — a failure in one service does not bring down its callers.
  Flag synchronous call chains (A → B → C → D) with no bulkheads, failure isolation, or fallbacks.
- **Bounded result sets** — cross-service queries return bounded, paginated results.
  Flag `getAllX()` endpoints with no pagination, limit, or streaming.
- **Data ownership** — each service owns its data store exclusively.
  Flag shared databases, shared schemas, or direct SQL access to another service's tables.
- **Temporal decoupling** — operations do not depend on implicit ordering.
  Flag services that must call B before C with no enforced ordering at the API level.
- **Explicit contracts** — services communicate via defined contracts (OpenAPI, Protobuf, AsyncAPI).
  Flag integration without formal contract definitions.
- **Thundering herd avoidance** — cache expiration and retry strategies use jitter to prevent coordinated spikes.
  Flag simultaneous cache expiry or synchronised retry storms.
- **Critical path separation** — non-critical dependencies are not in the synchronous request path.
  Flag synchronous calls to analytics, audit logging, or recommendations in user-facing request handlers.

## Anti-Patterns

### YL-01: Unprotected integration point

External call with no timeout, no failure isolation, no error handling.
A slow or failing dependency can block all calling threads, rendering the caller unresponsive.

```python
# No timeout, no failure isolation
response = requests.get(f"http://downstream/api/data")

# Protected with timeout
response = requests.get(f"http://downstream/api/data", timeout=(3, 10))
```

**Principle:** Loose Coupling, Explicit over Implicit | **Severity:** HIGH / HYG

### YL-02: Cascading failure path

A synchronous call chain (A → B → C → D) where one service's failure brings down all upstream callers.
No bulkheads, no failure isolation, no fallbacks between services.
**Principle:** Loose Coupling | **Severity:** HIGH / HYG

### YL-03: Unbounded result sets

Cross-service queries that return unbounded results — `getAllOrders()`, `findUsers()` with no pagination, limit, or streaming.

```python
orders = order_service.get_all_orders()                # unbounded
orders = order_service.get_orders(page=1, limit=100)   # bounded
```

**Principle:** Explicit over Implicit | **Severity:** HIGH / L1

### YL-04: Shared database across services

Multiple services accessing the same database tables.
Schema changes break unknown consumers; locking contention causes unpredictable latency.
**Principle:** Loose Coupling | **Severity:** HIGH / HYG

### YL-05: Temporal coupling

Service A must call B before C; operations have implicit ordering requirements not enforced by the API.
**Principle:** Explicit over Implicit | **Severity:** MEDIUM / L2

### YL-06: Missing contract

Services communicate via HTTP/gRPC/messaging with no formal contract definition.
Breaking changes discovered at runtime, not at build time.
**Principle:** Explicit over Implicit | **Severity:** MEDIUM / L1

### YL-07: Dogpile / thundering herd

All instances expire cache entries at the same time, all hit the database simultaneously.
Creates periodic spikes that can cause cascading failure.
**Principle:** Loose Coupling | **Severity:** MEDIUM / L2

### YL-08: Synchronous call to non-critical dependency

A user-facing request handler makes a synchronous call to analytics, recommendations, or audit logging.
Non-critical dependency failure degrades or blocks the critical path.
**Principle:** Separation of Concerns | **Severity:** MEDIUM / L2

## Checklist

- [ ] Do external calls have timeouts and failure isolation?
- [ ] Can a single service failure cascade beyond its boundary to callers?
- [ ] Are cross-service query results bounded with pagination or limits?
- [ ] Does any service share database tables with another service?
- [ ] Are there implicit ordering requirements between service calls not enforced by the API?
- [ ] Do all inter-service interfaces have formal contracts (OpenAPI, Protobuf, AsyncAPI)?
- [ ] Can simultaneous cache expiry or coordinated retries cause load spikes?
- [ ] Are non-critical dependencies (analytics, audit) in the synchronous request path?
- [ ] Can each service operate independently when non-critical dependencies are unavailable?
- [ ] Are integration failure modes documented and tested?

## Positive Indicators

- External dependencies protected with timeouts and failure isolation.
- Failure in one service contained without cascading to callers.
- Inter-service contracts formally defined and version-managed.
- Non-critical dependencies decoupled from the critical request path.
