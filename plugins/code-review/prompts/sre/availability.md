## Availability Pillar

**Mandate:** Does the system meet SLOs and degrade gracefully?

Reviews fault tolerance, dependency management, and failure isolation to ensure the system survives partial failures without total collapse.
If a dependency goes down, users should see degraded service, not a blank page.

### Focus Areas

- Retry loops are bounded with exponential backoff and jitter.
- Every external call has an explicit, appropriate timeout.
- Health checks verify real readiness, not just process existence.
- Non-critical dependencies are decoupled from the critical path.
- Degradation paths provide reduced functionality over total failure.
- Circuit breakers or equivalent have a recovery mechanism.

### SEEMS/FaCTOR Emphasis

| SEEMS focus | FaCTOR defence |
|-------------|----------------|
| Excessive load | Capacity |
| Excessive latency | Timeliness |
| Single points of failure | Redundancy |
| Shared fate | Fault isolation |

---

## Anti-Patterns

### AP-01: Unbounded retry

```python
while True:
    try:
        return payment_api.charge(order)
    except Exception:
        time.sleep(1)
```

Retry loop with no maximum attempt count.
Under dependency failure, every in-flight request retries indefinitely, overwhelming the dependency and preventing recovery.

**SEEMS:** Excessive load | **FaCTOR:** Capacity | **Typical:** HIGH / HYG (Total — can prevent dependency recovery)

### AP-02: Retry without backoff

```python
for attempt in range(3):
    try:
        return client.call(request)
    except Exception:
        time.sleep(1)  # Fixed delay
```

Retries with a fixed delay maintain constant pressure on the failing dependency, leaving no space for recovery.

**SEEMS:** Excessive load | **FaCTOR:** Capacity | **Typical:** HIGH / L1 (escalates to HYG if unbounded)

### AP-03: Retry without jitter

Exponential backoff where all clients use the same delay schedule (1s, 2s, 4s, 8s) with no randomisation.
Creates thundering herd — all clients that failed at the same time retry at the same time.

**SEEMS:** Excessive load | **FaCTOR:** Capacity | **Typical:** MEDIUM / L2

### AP-04: Missing timeout on external call

```python
response = requests.post(url, json=payload)
```

No explicit timeout.
A hung dependency blocks the calling thread indefinitely, and under failure all worker threads can be consumed, making the service unresponsive.

**SEEMS:** Excessive latency | **FaCTOR:** Timeliness | **Typical:** HIGH / HYG (Total — if in the request path)

### AP-05: Timeout longer than user patience

A 30-second or 60-second timeout on a call in a user-facing request where users wait 3-5 seconds.
The timeout "protects" the service but the user has already given up; resources are tied up serving a response nobody will receive.

**SEEMS:** Excessive latency | **FaCTOR:** Timeliness | **Typical:** MEDIUM / L2

### AP-06: Health check doesn't check dependencies

```python
@app.route("/health")
def health():
    return {"status": "healthy"}, 200
```

Returns 200 if the process is running, without verifying database, cache, or other critical dependencies.
The service reports healthy but cannot serve requests; load balancers route traffic to it.

**SEEMS:** Misconfiguration | **FaCTOR:** Availability | **Typical:** MEDIUM / L1

### AP-07: Health check too sensitive (flapping)

Health check fails on a single transient error without dampening.
Transient errors cause the health check to flap, and the orchestrator keeps adding and removing the instance, causing instability.

**SEEMS:** Single points of failure | **FaCTOR:** Availability | **Typical:** MEDIUM / L2

### AP-08: Synchronous call to non-critical service

A user-facing request handler making a synchronous call to analytics, recommendations, or audit logging in the request path.
If the non-critical service is slow or down, the critical user-facing request fails.

**SEEMS:** Shared fate | **FaCTOR:** Fault isolation | **Typical:** MEDIUM / L2

### AP-09: No fallback when cache is unavailable

Cache miss or failure causes the request to fail entirely, rather than falling back to the source of truth.
The cache was introduced for performance but became a hard dependency; cache failure = service failure.

**SEEMS:** Single points of failure | **FaCTOR:** Redundancy | **Typical:** MEDIUM / L2

### AP-10: Circuit breaker that never closes

Circuit breaker opens when a dependency fails but has no half-open state or recovery mechanism.
The circuit breaker correctly protects during failure but never allows recovery — permanent degradation.

**SEEMS:** Single points of failure | **FaCTOR:** Availability | **Typical:** MEDIUM / L2

---

## Review Checklist

A "no" answer is a potential finding; investigate before raising it.

- Do all retry loops have a maximum attempt count, exponential backoff, and jitter?
- Do all external calls (HTTP, database, cache, queue) have explicit timeouts appropriate for the operation?
- Does the health check verify at least one critical dependency and return unhealthy when the service cannot serve requests?
- Are non-critical dependencies decoupled from the critical request path (asynchronous or fire-and-forget)?
- Does the system provide a fallback or degradation path when a non-critical dependency is unavailable?
- Are circuit breakers (or equivalent isolation) configured with a recovery mechanism (half-open state or equivalent)?

### Maturity Mapping

- **L1 (1.1):** Health checks reflect real readiness (verify critical dependencies, distinguish liveness from readiness).
- **L1 (1.3):** External calls have explicit timeouts appropriate for the operation.
- **L2 (2.2):** External dependencies have failure isolation (separate pools, circuits, or bulkheads).
- **L2 (2.3):** Degradation paths exist for non-critical dependencies.
