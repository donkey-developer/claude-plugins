# Anti-Patterns Catalogue — SRE Domain

> Complete catalogue of code patterns that SRE reviewers should flag. Organised by ROAD pillar, with SEEMS/FaCTOR classification and typical severity.

## How to use this document

Each anti-pattern includes:
- **Pattern name** — a short, memorable label
- **What it looks like** — concrete code description
- **Why it's bad** — production impact
- **SEEMS/FaCTOR** — which failure mode and which missing resilience property
- **Typical severity** — default assessment (may be higher or lower depending on context)

When adding new anti-patterns to prompts, follow this structure. Use concrete descriptions, not abstract categories.

---

## Response Pillar Anti-Patterns

### RP-01: Generic error message

**What it looks like:** Error responses that say "An error occurred", "Something went wrong", "Internal server error" with no additional context.

**Why it's bad:** On-call engineers cannot distinguish a config error from a dependency failure from a code bug. Every incident starts with "read the code" instead of "read the error".

**SEEMS:** Misconfiguration (can't diagnose config errors)
**FaCTOR:** Fault isolation (failure not attributed to correct component)
**Typical severity:** MEDIUM / L1

### RP-02: Swallowed exception

**What it looks like:** `catch (Exception e) { }` or `except Exception: pass` — exception caught with no logging, no re-throw, no metric.

**Why it's bad:** The failure is invisible. Upstream callers may believe the operation succeeded. Data can be silently lost.

**SEEMS:** Misconfiguration (failure is undiagnosable)
**FaCTOR:** Output correctness (caller gets wrong signal about success/failure)
**Typical severity:** HIGH / HYG (Irreversible — if the swallowed error masks data loss)

### RP-03: Stack trace in API response

**What it looks like:** Exception stack traces returned in HTTP response bodies to external callers.

**Why it's bad:** Exposes internal implementation details. May contain file paths, dependency names, or connection strings. Unhelpful to API consumers.

**SEEMS:** Misconfiguration (error output misconfigured)
**FaCTOR:** Output correctness (error response is not well-formed)
**Typical severity:** MEDIUM / L1 (escalates to HYG if stack trace contains credentials or PII)

### RP-04: Missing correlation IDs

**What it looks like:** Logs from different services or different operations within a request have no shared identifier. No request ID, no trace ID, no correlation token.

**Why it's bad:** When a user reports a problem, operators cannot trace the request through the system. Diagnosis requires time-based log correlation (error-prone and slow).

**SEEMS:** Shared fate (cross-service failure diagnosis impossible)
**FaCTOR:** Fault isolation (cannot attribute failure to originating component)
**Typical severity:** MEDIUM / L1

### RP-05: No error classification

**What it looks like:** All errors treated the same — no distinction between retryable (timeout, rate limit) and permanent (bad request, not found) errors.

**Why it's bad:** Clients retry permanent errors (wasting resources) or give up on retryable errors (unnecessary failure). Automated retry logic can't make correct decisions.

**SEEMS:** Excessive load (retrying permanent errors amplifies load)
**FaCTOR:** Output correctness (error semantics don't guide correct client behaviour)
**Typical severity:** MEDIUM / L1

### RP-06: Errors require code reading

**What it looks like:** Error messages reference internal variable names, enum values, or error codes that only make sense if you've read the source code. E.g., "ERR_STATE_7" or "InvalidTransition: state=PENDING_REVIEW".

**Why it's bad:** On-call engineers (who may not have written the code) cannot understand the error without finding and reading the relevant source file.

**SEEMS:** Misconfiguration (cannot diagnose without code access)
**FaCTOR:** Fault isolation (failure diagnosis blocked by indirection)
**Typical severity:** LOW / L1

---

## Observability Pillar Anti-Patterns

### OP-01: Print/console.log instead of structured logging

**What it looks like:** `print(f"Processing order {order_id}")` or `console.log("Error:", err)` — unstructured text output.

**Why it's bad:** No log level (can't filter errors from debug), no structured fields (can't query), no correlation (can't trace), no standard format (can't parse).

**SEEMS:** Misconfiguration (can't diagnose from logs)
**FaCTOR:** Timeliness (can't measure from log signals)
**Typical severity:** MEDIUM / L1

### OP-02: Logging entire objects

**What it looks like:** `logger.info("Request received", extra={"request": request.__dict__})` — serialising full objects into logs.

**Why it's bad:** PII risk (user data, passwords, tokens may be in the object). Log bloat (large objects generate kilobytes per log line). Performance impact in hot paths.

**SEEMS:** Misconfiguration (PII exposure)
**FaCTOR:** Capacity (log volume can overwhelm log infrastructure)
**Typical severity:** MEDIUM / L1 (escalates to HYG if PII is logged — Regulated)

### OP-03: Unbounded metric cardinality

**What it looks like:** Metric labels that use unbounded values: `user_id`, `request_path` (with path parameters), `session_id`, `order_id`.

**Why it's bad:** Each unique label combination creates a new time series. Unbounded cardinality exhausts the metrics backend's memory and storage, eventually crashing the monitoring system.

**SEEMS:** Excessive load (amplifies monitoring infrastructure load)
**FaCTOR:** Capacity (monitoring system resource limits exceeded)
**Typical severity:** HIGH / L2 (escalates to HYG if the metrics backend is shared — Total)

### OP-04: Missing units on metrics

**What it looks like:** `metrics.histogram("request_duration", duration)` — no indication whether `duration` is in milliseconds, seconds, or nanoseconds.

**Why it's bad:** Dashboards and alerts are misconfigured. A "500ms" SLO alert triggers on a value that's actually 500 nanoseconds, or misses a 500-second value.

**SEEMS:** Misconfiguration (metric misinterpretation)
**FaCTOR:** Timeliness (SLO measurement is wrong)
**Typical severity:** LOW / L2

### OP-05: Tracing only happy paths

**What it looks like:** Trace spans created for successful operations but not for error paths. Errors don't set span status or record exception details.

**Why it's bad:** The failures you most need to trace are invisible in the tracing system. The tracing tool shows the request started but not why it failed.

**SEEMS:** Misconfiguration (can't diagnose failures from traces)
**FaCTOR:** Fault isolation (can't attribute failure to correct span)
**Typical severity:** MEDIUM / L2

### OP-06: No user-to-system correlation

**What it looks like:** No way to go from a user complaint ("my request failed at 2:15pm") to the system's view of that request. No request ID exposed to the user, no way to search by user ID + time.

**Why it's bad:** Customer support tickets require manual log diving. Incident response starts with "which request?" instead of "what happened?".

**SEEMS:** Misconfiguration (can't diagnose user-reported issues)
**FaCTOR:** Fault isolation (can't connect user experience to system behaviour)
**Typical severity:** MEDIUM / L1

### OP-07: Averages instead of percentiles

**What it looks like:** Latency measured as an average (mean) rather than as a histogram with percentile computation.

**Why it's bad:** Averages hide tail latency. A service with 1ms average and 10-second P99 looks healthy by average but is terrible for 1% of users. SLOs based on averages are meaningless.

**SEEMS:** Excessive latency (tail latency is invisible)
**FaCTOR:** Timeliness (SLO measurement is misleading)
**Typical severity:** MEDIUM / L2

---

## Availability Pillar Anti-Patterns

### AP-01: Unbounded retry

**What it looks like:** `while True: try ... except: retry` — retry loop with no maximum attempt count.

**Why it's bad:** Under dependency failure, every in-flight request retries indefinitely. Load on the failing dependency increases instead of decreasing. Recovery becomes impossible because the retry traffic overwhelms the dependency the moment it tries to come back.

**SEEMS:** Excessive load
**FaCTOR:** Capacity (no bound on retry-generated load)
**Typical severity:** HIGH / HYG (Total — can take down the service and prevent dependency recovery)

### AP-02: Retry without backoff

**What it looks like:** Retry with a fixed delay (e.g., `sleep(1)` between retries) or no delay at all.

**Why it's bad:** All retries fire at the same interval, maintaining constant pressure on the failing dependency. No space for recovery.

**SEEMS:** Excessive load
**FaCTOR:** Capacity
**Typical severity:** HIGH / L1 (escalates to HYG if unbounded)

### AP-03: Retry without jitter

**What it looks like:** Exponential backoff but all clients use the same delay schedule (e.g., 1s, 2s, 4s, 8s with no randomisation).

**Why it's bad:** Thundering herd — all clients that failed at the same time retry at the same time, creating periodic spikes of load on the dependency.

**SEEMS:** Excessive load
**FaCTOR:** Capacity
**Typical severity:** MEDIUM / L2

### AP-04: Missing timeout on external call

**What it looks like:** HTTP, database, cache, or queue client call with no explicit timeout.

**Why it's bad:** A hung dependency blocks the calling thread indefinitely. Under failure, all worker threads can be consumed, making the service completely unresponsive.

**SEEMS:** Excessive latency
**FaCTOR:** Timeliness
**Typical severity:** HIGH / HYG (Total — if in the request path)

### AP-05: Timeout longer than user patience

**What it looks like:** A 30-second or 60-second timeout on a call that's part of a user-facing request where users wait 3-5 seconds.

**Why it's bad:** The timeout "protects" the service but the user has already given up and retried (or left). Resources are tied up serving a response nobody will receive.

**SEEMS:** Excessive latency
**FaCTOR:** Timeliness
**Typical severity:** MEDIUM / L2

### AP-06: Health check doesn't check dependencies

**What it looks like:** Health check returns 200 if the process is running, without verifying database, cache, or other critical dependencies.

**Why it's bad:** The service reports healthy but can't serve requests. Load balancers route traffic to it. Users get errors.

**SEEMS:** Misconfiguration
**FaCTOR:** Availability
**Typical severity:** MEDIUM / L1

### AP-07: Health check too sensitive (flapping)

**What it looks like:** Health check fails on a single transient error (one failed DB query) without any dampening.

**Why it's bad:** Transient errors cause the health check to flap between healthy and unhealthy. The orchestrator/load balancer keeps adding and removing the instance, causing instability.

**SEEMS:** Single points of failure (availability depends on a single probe)
**FaCTOR:** Availability
**Typical severity:** MEDIUM / L2

### AP-08: Synchronous call to non-critical service

**What it looks like:** A user-facing request handler that makes a synchronous call to a non-critical service (analytics, recommendations, audit logging) in the request path.

**Why it's bad:** If the non-critical service is slow or down, the critical user-facing request is degraded or fails. Non-critical work should not block critical paths.

**SEEMS:** Shared fate (non-critical dependency failure cascades to critical path)
**FaCTOR:** Fault isolation
**Typical severity:** MEDIUM / L2

### AP-09: No fallback when cache is unavailable

**What it looks like:** Cache miss or cache failure causes the request to fail entirely, rather than falling back to the source of truth (database, API).

**Why it's bad:** The cache was introduced to improve performance, but it became a hard dependency. Cache failure = service failure.

**SEEMS:** Single points of failure (cache is a SPOF)
**FaCTOR:** Redundancy
**Typical severity:** MEDIUM / L2

### AP-10: Circuit breaker that never closes

**What it looks like:** Circuit breaker opens when a dependency fails but has no half-open state or recovery mechanism. Once open, it stays open permanently.

**Why it's bad:** The circuit breaker correctly protects the service during failure but never allows recovery. The dependency recovers but the service never notices. Permanent degradation.

**SEEMS:** Single points of failure (recovery path is broken)
**FaCTOR:** Availability
**Typical severity:** MEDIUM / L2

---

## Delivery Pillar Anti-Patterns

### DP-01: Non-reversible database migration

**What it looks like:** `DROP COLUMN`, `DROP TABLE`, data type narrowing, or `RENAME COLUMN` without a two-phase approach.

**Why it's bad:** If the new code has a bug and needs rollback, the old code expects the dropped/renamed schema. Rollback requires a backup restore = downtime.

**SEEMS:** Misconfiguration (deployment error causes data loss)
**FaCTOR:** Output correctness (old and new versions can't coexist)
**Typical severity:** HIGH / HYG (Irreversible — data/schema permanently changed)

### DP-02: Breaking API change without versioning

**What it looks like:** Removing or renaming a field in an API response. Changing the type of a field. Removing an endpoint.

**Why it's bad:** Existing clients break. If the change is deployed gradually (canary/rolling), some clients hit old instances and some hit new ones — intermittent failures.

**SEEMS:** Shared fate (deployment affects all consumers simultaneously)
**FaCTOR:** Output correctness (inconsistent results during rollout)
**Typical severity:** HIGH / L1

### DP-03: Config change requires coordinated deployment

**What it looks like:** A config value in Service A that must match a corresponding value in Service B. Updating one without the other causes failures.

**Why it's bad:** Coordinated deployments are fragile. If one deploy succeeds and the other fails (or is delayed), the system is in an inconsistent state.

**SEEMS:** Shared fate (services coupled through config)
**FaCTOR:** Fault isolation (one service's deployment failure cascades)
**Typical severity:** MEDIUM / L2

### DP-04: Removing feature flag before stabilisation

**What it looks like:** A feature flag is removed (code hardcoded to the new behaviour) before the feature has been running in production long enough to confirm stability.

**Why it's bad:** If a latent bug surfaces after flag removal, the only remediation is a full code rollback. With the flag, the team could disable the feature in seconds.

**SEEMS:** Misconfiguration (no way to disable the feature)
**FaCTOR:** Availability (no kill switch)
**Typical severity:** MEDIUM / L2

### DP-05: Deployment requires downtime

**What it looks like:** A change that requires stopping the old version before starting the new one (e.g., because they can't coexist, or because a migration requires exclusive access).

**Why it's bad:** Every deployment is a planned outage. Deployment frequency is constrained by downtime windows. Hotfixes are delayed.

**SEEMS:** Shared fate (deployment and availability are coupled)
**FaCTOR:** Availability (service unavailable during deployment)
**Typical severity:** MEDIUM / L3

### DP-06: Missing health check for new functionality

**What it looks like:** A new feature or endpoint is added but the health check is not updated to verify the new functionality's dependencies.

**Why it's bad:** The health check says "healthy" even if the new feature's dependencies are down. Traffic is routed to an instance that can't serve the new feature.

**SEEMS:** Misconfiguration (health check doesn't reflect true readiness)
**FaCTOR:** Availability
**Typical severity:** MEDIUM / L1

### DP-07: Hardcoded values that should be configurable

**What it looks like:** Timeout values, connection pool sizes, feature thresholds, or service URLs hardcoded in source code.

**Why it's bad:** Changing these values requires a code change and deployment. In an incident, you can't adjust behaviour without a deploy.

**SEEMS:** Misconfiguration (can't adjust without deploy)
**FaCTOR:** Availability (can't respond to incidents with config changes)
**Typical severity:** LOW / L1

### DP-08: Secrets in code or config files

**What it looks like:** API keys, passwords, tokens, or connection strings committed to source code or checked-in config files.

**Why it's bad:** Secrets are exposed to anyone with repo access. They end up in CI logs, Docker images, and backups. Rotation requires a code change and deploy.

**SEEMS:** Misconfiguration
**FaCTOR:** Fault isolation (compromised secret affects everything that uses it)
**Typical severity:** HIGH / HYG (Irreversible — once committed, the secret is in git history forever)

### DP-09: Dependencies on deployment order

**What it looks like:** Service A must be deployed before Service B, or Database migration must run before Service C starts.

**Why it's bad:** Deployment ordering is fragile and poorly communicated. If the order is violated (by automation, by a new team member, by parallel deploys), the system breaks.

**SEEMS:** Shared fate (services coupled through deployment order)
**FaCTOR:** Fault isolation (one deployment's timing affects others)
**Typical severity:** MEDIUM / L2

---

## Adding New Anti-Patterns

When adding a new anti-pattern to this catalogue or to the prompts:

1. Give it a **short, memorable name** (not "Bad Practice #7")
2. Describe **what it looks like** in code (concrete, not abstract)
3. Explain **why it's bad** in terms of production impact
4. Classify with **SEEMS category** and **FaCTOR property**
5. Assign a **typical severity** with reasoning
6. Note **boundary conditions** that would change the severity
