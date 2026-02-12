# Maturity Criteria — SRE Domain

> Detailed criteria for each maturity level with defined "sufficient" thresholds. Use this when assessing criteria as Met / Not met / Partially met.

## Hygiene Gate

The Hygiene gate is not a maturity level — it is a promotion gate. Any finding at any level that passes any of the three tests is promoted to `HYG`.

### Test 1: Irreversible

**Question:** If this goes wrong, can the damage be undone?

**Threshold:** If a failure would produce damage that requires more than a rollback/restart to fix — e.g., corrupted data that has been served to users, leaked credentials that must be rotated, lost records with no backup — this is irreversible.

**SRE examples that trigger this test:**
- Catch-all exception handler that swallows errors and returns success, masking data loss to upstream consumers
- Write path with no idempotency that can produce duplicate records on retry
- Background job that deletes records before confirming downstream receipt
- Error handler that logs to a buffer with no flush guarantee — logs lost on crash

**SRE examples that do NOT trigger this test:**
- Missing retry logic (service returns an error, but the error is visible and the user can retry)
- Suboptimal timeout value (causes degraded experience, but no lasting damage)

### Test 2: Total

**Question:** Can this take down the entire service or cascade beyond its boundary?

**Threshold:** If a failure can exhaust a shared resource (threads, connections, memory, CPU) to the point where the entire service becomes unresponsive, or if the failure propagates to other services beyond its boundary, this is total.

**SRE examples that trigger this test:**
- Retry loop with no bound and no backoff — under dependency failure, retries consume all threads/connections
- Health check hardcoded to return healthy — load balancer routes traffic to a dead instance, all requests to that instance fail
- Synchronous call to an external service with no timeout in the request path — one slow dependency blocks all request processing
- Unbounded queue that grows under load until memory is exhausted
- Connection pool shared between critical and non-critical paths — non-critical traffic can starve critical requests

**SRE examples that do NOT trigger this test:**
- A single endpoint returns a 500 error (contained failure, other endpoints still work)
- A background job fails and stops processing (localised impact, not service-wide)

### Test 3: Regulated

**Question:** Does this violate a legal or compliance obligation?

**Threshold:** If the code would cause a breach of data protection law, financial regulation, accessibility requirements, or other legal obligations, this is regulated.

**SRE examples that trigger this test:**
- PII (emails, phone numbers, health data) logged to stdout without masking
- Error responses that include internal user data (names, addresses) in the response body
- Health/medical data stored without encryption at rest

**SRE examples that do NOT trigger this test:**
- Internal service-to-service request IDs in logs (not PII)
- Internal IP addresses in error messages (not regulated data in most contexts)

---

## Level 1 — Foundations

**Overall intent:** The basics are in place. The system can be operated. An on-call engineer has enough information to respond to incidents.

### Criterion 1.1: Health checks reflect real readiness

**Definition:** Liveness and readiness probes test actual service functionality, not just process existence.

**Met (sufficient):**
- Health check endpoint exists
- It verifies at least one critical dependency (database connectivity, cache reachability, or equivalent)
- It returns unhealthy when the service cannot serve requests
- It distinguishes between liveness (process is running) and readiness (can accept traffic)

**Partially met:**
- Health check exists but only checks process liveness (returns 200 if the process is running)
- Health check exists but doesn't verify any dependencies

**Not met:**
- No health check endpoint
- Health check hardcoded to return 200 / "OK"
- Health check exists but is never called (not wired into infrastructure)

### Criterion 1.2: Errors propagate with context sufficient for diagnosis

**Definition:** When an error occurs, enough information is captured for an operator to understand what happened without reading the source code.

**Met (sufficient) — minimum context:**
- **What** failed: error type or category (not just a generic message)
- **Where** it failed: service name + operation/endpoint
- **Correlation**: request ID or trace ID that connects the error to the originating request
- **Classification**: whether the error is retryable or permanent (via status code, error type, or explicit field)

**Partially met:**
- Some errors have good context, others are generic ("An error occurred")
- Correlation IDs exist but are not propagated across async boundaries or service calls
- Error types are distinguishable but missing request correlation

**Not met:**
- Generic catch blocks that log "error occurred" with no context
- Exceptions swallowed silently (catch with no logging)
- Stack traces are the only error information (requires code reading to interpret)
- No correlation IDs anywhere in the codebase

### Criterion 1.3: External calls have explicit timeouts

**Definition:** Every call to an external dependency (HTTP, database, cache, queue, filesystem, third-party API) has an explicit timeout configured.

**Met (sufficient):**
- All external calls have timeouts
- Timeout values are appropriate for the operation (not just a copy-pasted default)
- Connect timeout and read timeout are distinguished where the client supports it
- Timeout values are documented or self-evident from context

**Partially met:**
- Some external calls have timeouts, others rely on library/framework defaults
- Timeouts exist but values are inappropriate (e.g., 5-minute timeout on a user-facing API call)

**Not met:**
- Any external call with no explicit timeout
- Reliance on "the library has a default" without knowing what that default is

### Criterion 1.4: Logging is structured with request correlation

**Definition:** Log output uses structured format (JSON or key-value pairs) and includes correlation identifiers that connect log entries to specific requests.

**Met (sufficient):**
- Structured logging format (JSON, key-value, or equivalent — not string interpolation with `f"message {var}"`)
- Log levels used correctly: ERROR for errors, WARN for recoverable issues, INFO for significant operations, DEBUG for details
- Request/trace ID included in log entries for request-scoped operations
- PII is not present in log output (or is explicitly masked)

**Partially met:**
- Structured format used but no correlation IDs
- Correlation IDs present but logging format is unstructured (plain text with interpolated values)
- Most logging is structured but some paths use `print()` or `console.log()`

**Not met:**
- All logging is `print()` / `console.log()` / unstructured
- No correlation IDs
- PII logged without masking

---

## Level 2 — Hardening

**Overall intent:** Production-ready practices. The system can be operated *well*. Teams can set and track reliability targets.

**Prerequisite:** All L1 criteria must be met.

### Criterion 2.1: Service-level objectives are defined and measurable from telemetry

**Definition:** The codebase emits signals (metrics, logs, or traces) that can be used to compute SLIs and track them against defined SLO targets.

**Met (sufficient):**
- SLI-relevant metrics are emitted: request latency (as histogram, not average), error rate (by type), throughput
- Metrics can be used to compute SLOs (e.g., "99th percentile latency < 500ms", "error rate < 0.1%")
- Metrics are labelled to distinguish SLO-relevant paths from SLO-exempt paths (health checks, admin endpoints)
- Metric cardinality is bounded (no unbounded label values like user_id)

**Partially met:**
- Some SLI metrics exist but not all (e.g., latency but no error rate by type)
- Metrics exist but use averages instead of percentiles for latency
- Metrics exist but cardinality is unbounded

**Not met:**
- No SLI-relevant metrics emitted
- Only business metrics, no request-level SLI metrics
- Latency measured only as averages

### Criterion 2.2: External dependencies have failure isolation

**Definition:** When an external dependency fails, the failure does not propagate unchecked through the system. Some form of isolation exists.

**Met (sufficient):**
- Dependency failures are detected (timeout, error response, connection refused)
- Failure is contained: the calling code handles the failure without crashing or blocking
- There is some form of isolation: separate connection pools per dependency, circuit breaker patterns, bulkhead thread pools, or equivalent
- Failure of a non-critical dependency does not affect the critical path

**Partially met:**
- Failures are handled (no crash) but there's no isolation between dependencies (shared connection pool, shared thread pool)
- Circuit breaker or equivalent exists for some dependencies but not all external ones

**Not met:**
- Dependency failure causes the service to crash or hang
- All dependencies share a single connection pool or thread pool
- No distinction between critical and non-critical dependency failures

### Criterion 2.3: Degradation paths exist

**Definition:** The system can provide reduced functionality when a dependency is unavailable, rather than failing entirely.

**Met (sufficient):**
- At least one degradation path exists for non-critical dependencies (cached data, default values, reduced feature set)
- The degradation is intentional and documented (not accidental)
- The system communicates its degraded state (via metrics, logs, or health check status)

**Partially met:**
- Degradation exists for some paths but the service fails totally for others that could be degraded
- Degradation exists but the system doesn't communicate its degraded state

**Not met:**
- No degradation paths — any dependency failure causes total failure
- Degradation exists only by accident (e.g., empty catch blocks that return null)

### Criterion 2.4: Alert definitions reference response procedures

**Definition:** Alerting signals in the code are accompanied by context that helps operators respond.

**Met (sufficient):**
- Critical failure paths emit a signal (metric or log) that could be used as an alert trigger
- Error messages or metric names are specific enough to identify the failure type (not just "error_count" but "dependency_timeout_count" or equivalent)
- Alert-worthy signals distinguish between symptoms and causes

**Partially met:**
- Some alert-worthy signals exist but they're too generic to be actionable
- Critical paths emit signals but there's no way to distinguish failure types from the signal alone

**Not met:**
- Critical failure paths don't emit any signal that could be alerted on
- All errors produce the same metric/log — no way to distinguish failure types

---

## Level 3 — Excellence

**Overall intent:** Best-in-class. The system is a model for others. Reliability is a first-class engineering discipline.

**Prerequisite:** All L2 criteria must be met.

### Criterion 3.1: Deployment can proceed without downtime

**Definition:** The deployment strategy supports zero-downtime releases.

**Met (sufficient):**
- Code changes are backward compatible with the previous version
- Database migrations (if any) are backward compatible (add-before-remove pattern)
- Old and new versions can coexist during rollout
- Rollback is possible without data loss

**Partially met:**
- Most changes are backward compatible but some require coordinated deployment
- Rollback is possible but with some data loss or manual intervention

**Not met:**
- Deployment requires downtime
- Database migrations are irreversible
- Breaking changes deployed without feature flags or versioning

### Criterion 3.2: Capacity limits are enforced under load

**Definition:** The system actively protects itself when load exceeds capacity.

**Met (sufficient):**
- Request admission control exists (reject requests when overloaded rather than accepting and failing slowly)
- Queue depths are bounded
- Resource consumption (memory, connections, threads) has defined limits
- Load shedding prioritises critical over non-critical work

**Partially met:**
- Some capacity limits exist but not comprehensive (e.g., queue depth bounded but no request admission control)
- Limits exist but are not tested under load

**Not met:**
- No capacity limits — system accepts all work regardless of load
- Unbounded queues or resource pools

### Criterion 3.3: Failure scenarios are codified as automated tests

**Definition:** Known failure modes are tested, not just hoped-for.

**Met (sufficient):**
- Tests exist for key failure scenarios: dependency timeout, dependency error, invalid input, resource exhaustion
- Tests verify the system's behaviour under failure (graceful degradation, correct error response), not just that it doesn't crash
- Failure tests are part of the CI pipeline

**Partially met:**
- Some failure tests exist but coverage is spotty
- Failure tests exist but only check "doesn't crash", not correct behaviour

**Not met:**
- No failure-scenario tests
- Only happy-path tests

### Criterion 3.4: Resource consumption is bounded and observable

**Definition:** The system's resource usage can be seen and is constrained.

**Met (sufficient):**
- Resource metrics are emitted: memory usage, connection pool utilisation, thread pool usage, queue depth
- Resource limits are configured (container memory limits, connection pool sizes, thread pool sizes)
- Resource consumption can be correlated with request load (to identify leaks and scaling needs)

**Partially met:**
- Some resource metrics exist but not comprehensive
- Limits are configured but resource usage isn't observable (or vice versa)

**Not met:**
- No resource metrics
- No resource limits configured
