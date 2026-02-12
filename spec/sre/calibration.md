# Calibration Examples — SRE Domain

> Worked examples showing how to judge severity and maturity level for real code patterns. Use these to calibrate prompt output and verify consistency across reviews.

## How to use this document

Each example follows the same four-part structure used across all domain calibration documents:
1. **Code pattern** — what the reviewer sees
2. **Assessment** — severity, maturity level, SEEMS/FaCTOR category
3. **Reasoning** — why this severity and level, not higher or lower
4. **Boundary note** — what would change the assessment up or down

---

## Response Pillar

### Example R1: Generic error message (MEDIUM / L1)

**Code pattern:**
```python
except Exception as e:
    logger.error("Failed to process request")
    return {"error": "An error occurred"}, 500
```

**Assessment:** MEDIUM | L1 | Fault isolation

**Reasoning:** The error message is generic — an operator cannot distinguish a database failure from a config error from a code bug. However, the error IS logged (not swallowed), and the service returns a 500 (not a 200). The caller knows something failed. This is a L1 gap (errors don't propagate with sufficient context) but not Hygiene because the failure is visible, not masked.

**Boundary — would be HIGH / HYG if:**
```python
except Exception:
    return {"status": "ok"}, 200  # Swallows error, returns success
```
This masks data loss (irreversible) — the caller believes the operation succeeded.

**Boundary — would be LOW / L2 if:**
```python
except Exception as e:
    logger.error("Failed to process request", extra={"error": str(e), "request_id": req_id})
    return {"error": "Internal server error", "request_id": req_id}, 500
```
Context exists for diagnosis but there's no error categorisation (retryable vs permanent) — that's an L2 concern.

### Example R2: Swallowed exception (HIGH / HYG)

**Code pattern:**
```python
try:
    await publish_event(order_completed)
except Exception:
    pass  # Don't let event publishing block the order flow
```

**Assessment:** HIGH | HYG | Fault isolation (Irreversible test: yes)

**Reasoning:** The event is silently dropped. Downstream consumers (billing, analytics, notifications) will never receive it. There is no dead letter queue, no retry, no log. The data loss is irreversible — the event is gone and nobody knows it's missing.

**Boundary — would be MEDIUM / L1 if:**
```python
except Exception as e:
    logger.warning("Failed to publish order event, will retry", extra={"order_id": order.id, "error": str(e)})
    await retry_queue.enqueue(order_completed)
```
The failure is logged, retried, and recoverable. Now it's an L1 concern about whether the retry mechanism is robust enough.

### Example R3: Stack trace in API response (MEDIUM / L1)

**Code pattern:**
```python
except Exception as e:
    return {"error": traceback.format_exc()}, 500
```

**Assessment:** MEDIUM | L1 | Output correctness

**Reasoning:** Stack traces expose internal implementation details to callers. This is an L1 gap (error responses aren't well-formed). Not HIGH because it's an information disclosure issue more than an operational reliability issue — the service still correctly signals failure.

**Boundary — would be HIGH / HYG if:** The stack trace contains database connection strings, credentials, or PII (Regulated test: yes).

---

## Observability Pillar

### Example O1: Print statements instead of logging (MEDIUM / L1)

**Code pattern:**
```python
def process_order(order):
    print(f"Processing order {order.id}")
    result = payment_service.charge(order.total)
    print(f"Payment result: {result}")
```

**Assessment:** MEDIUM | L1 | Observability (missing structured logging)

**Reasoning:** `print()` produces unstructured output with no log level, no timestamp (beyond terminal), no correlation ID, and no way to filter by severity. This is a clear L1 gap. MEDIUM because the information IS emitted (not silent), but it's unusable for production diagnosis.

**Boundary — would be HIGH / L1 if:** The `print()` is in a catch block and it's the only signal of a failure — meaning critical errors are invisible to alerting systems.

**Boundary — would be LOW / L2 if:** Structured logging exists but some non-critical debug paths still use `print()`.

### Example O2: Unbounded metric cardinality (HIGH / L2)

**Code pattern:**
```python
metrics.histogram(
    "request_duration",
    duration,
    labels={"endpoint": path, "user_id": user.id}
)
```

**Assessment:** HIGH | L2 | Capacity

**Reasoning:** Using `user_id` as a metric label creates unbounded cardinality — one time series per user. This will eventually exhaust the metrics backend's memory/storage and crash the monitoring system. This is HIGH because it can cause a cascading failure in the observability infrastructure itself.

**Boundary — Hygiene (Total) if:** The metrics backend is shared across services and unbounded cardinality from this service can take down monitoring for all services.

**Boundary — MEDIUM / L2 if:** The label is something like `customer_tier` (a small, bounded set of values) that just needs documentation.

### Example O3: No SLI metrics emitted (MEDIUM / L2)

**Code pattern:** A request handler that processes HTTP requests but emits no latency histogram, no error counter, and no throughput metric.

**Assessment:** MEDIUM | L2 | Timeliness

**Reasoning:** Without SLI metrics, the team cannot define or measure SLOs. They cannot set alerts on latency percentiles or error rates. This is an L2 gap (SLOs not measurable from telemetry). MEDIUM because the service may still have logs that provide some visibility, but quantitative SLO tracking is impossible.

---

## Availability Pillar

### Example A1: Unbounded retry with no backoff (HIGH / HYG)

**Code pattern:**
```python
def call_payment_service(order):
    while True:
        try:
            return payment_api.charge(order)
        except Exception:
            time.sleep(1)  # Fixed 1-second delay, no backoff, no bound
```

**Assessment:** HIGH | HYG | Excessive load (Total test: yes)

**Reasoning:** Under dependency failure, this retries forever at a fixed 1-second interval. If 1000 requests are in flight when the payment service goes down, they all retry every second indefinitely — generating 1000 req/s of retry traffic on top of new incoming requests. This is a retry storm that can exhaust threads, connections, and overwhelm the dependency when it tries to recover. Total: can take down the service and prevent the dependency from recovering.

**Boundary — would be MEDIUM / L1 if:**
```python
for attempt in range(3):
    try:
        return payment_api.charge(order)
    except Exception:
        time.sleep(2 ** attempt)  # Bounded retries with exponential backoff
raise PaymentServiceUnavailable(order.id)
```
Bounded retries with backoff. Still missing jitter (thundering herd risk), which is an L1 concern.

### Example A2: Missing timeout on HTTP call (HIGH / HYG)

**Code pattern:**
```python
response = requests.post(url, json=payload)
```

**Assessment:** HIGH | HYG | Excessive latency (Total test: yes)

**Reasoning:** No timeout parameter. If the remote service hangs (accepts the connection but never responds), this call blocks the thread indefinitely. In a request-handling context, this blocks one worker thread per stuck request. Under dependency failure, all worker threads can be consumed, making the service completely unresponsive. Total: can render the entire service unresponsive.

**Boundary — would be MEDIUM / L1 if:** The call is in a background job with its own thread pool that cannot starve the request-handling path. Still a timeout gap (L1) but not service-fatal.

### Example A3: Health check always returns healthy (HIGH / HYG)

**Code pattern:**
```python
@app.route("/health")
def health():
    return {"status": "healthy"}, 200
```

**Assessment:** HIGH | HYG | Availability (Total test: yes)

**Reasoning:** This health check always returns healthy regardless of actual service state. If the database is down, if the service is out of memory, if a critical dependency is unreachable — the health check still says "healthy". Load balancers and orchestrators will continue routing traffic to a broken instance. Total: routes all traffic into a black hole.

**Boundary — would be MEDIUM / L1 if:**
```python
@app.route("/health")
def health():
    try:
        db.execute("SELECT 1")
        return {"status": "healthy"}, 200
    except Exception:
        return {"status": "unhealthy"}, 503
```
Checks one dependency but doesn't check others (cache, queue). L1 gap — health check is real but incomplete.

---

## Delivery Pillar

### Example D1: Irreversible database migration (HIGH / HYG)

**Code pattern:**
```sql
ALTER TABLE users DROP COLUMN legacy_email;
ALTER TABLE users RENAME COLUMN new_email TO email;
```

**Assessment:** HIGH | HYG | Output correctness (Irreversible test: yes)

**Reasoning:** This migration drops data (`legacy_email` column) and renames a column. If the new code has a bug and needs to be rolled back, the old code expects `legacy_email` to exist — but it's gone. The data is permanently lost. Rollback is impossible without a backup restore, which means downtime.

**Boundary — would be MEDIUM / L1 if:**
```sql
-- Step 1 (this deploy): Add new column, backfill
ALTER TABLE users ADD COLUMN email_v2 VARCHAR(255);
UPDATE users SET email_v2 = COALESCE(new_email, legacy_email);

-- Step 2 (next deploy, after verification): Remove old columns
```
Two-phase migration: add-before-remove. The first step is reversible.

### Example D2: Feature deployed without flag (MEDIUM / L2)

**Code pattern:** A new payment processing flow that replaces the old one, deployed directly without a feature flag.

**Assessment:** MEDIUM | L2 | Availability

**Reasoning:** If the new flow has a bug, the only remediation is a full rollback of the deployment. With a feature flag, the team could disable the new flow instantly (seconds) without a deploy (minutes to hours). This is an L2 concern — the feature works, but there's no operational control over it.

**Boundary — would be HIGH / HYG if:** The new flow changes data formats in a way that the old flow can't read, making rollback destructive (Irreversible).

### Example D3: Config requires coordinated deployment (MEDIUM / L2)

**Code pattern:** Service A reads a config value that must match a corresponding config in Service B. Updating one without the other causes failures.

**Assessment:** MEDIUM | L2 | Shared fate

**Reasoning:** Coordinated deployments are fragile — if one service deploys and the other doesn't (due to a failed deploy, a queue, or human error), the services are in an inconsistent state. This is an L2 concern about shared fate between services.

**Boundary — would be HIGH / HYG if:** The inconsistent state causes data corruption (Irreversible) or cascading failure (Total).

---

## Cross-pillar: How the same issue gets different assessments

### Missing timeout — assessed by different pillars

The same `requests.post(url, json=payload)` (no timeout) might be flagged by:

| Pillar | Category | Emphasis |
|--------|----------|----------|
| **Response** | Excessive latency | "Timeouts are not reported with context about what was being waited on" |
| **Observability** | Timeliness | "Cannot measure latency against SLO targets for this call" |
| **Availability** | Excessive latency | "Thread blocked indefinitely, can exhaust worker pool" (this is the HYG finding) |

**During synthesis:** These merge into one finding. The Availability pillar's assessment (HYG / Total) takes precedence as the highest severity. The recommendation combines: "Add explicit timeout (availability), log the timeout with dependency context (response), emit a latency metric for this call (observability)."
