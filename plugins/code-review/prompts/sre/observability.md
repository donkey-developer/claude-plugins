# Observability

Can operators see what the system is doing in production?

The Observability pillar evaluates whether logging, metrics, and tracing give on-call engineers the signals they need to understand system behaviour, measure SLOs, and diagnose failures without resorting to guesswork.
When this pillar is weak, incidents are diagnosed by intuition rather than evidence.

## Focus Areas

The Observability pillar applies the SEEMS/FaCTOR duality through two specific lenses.

### SEEMS focus (how the code fails)

- **Misconfiguration** — Misconfigured logging (wrong format, wrong level, PII in logs) makes the observability infrastructure itself untrustworthy.
  If you cannot rely on what the logs say, you cannot diagnose anything.
- **Excessive load** — Unbounded metric cardinality or excessive log volume can overwhelm the observability infrastructure.
  When the monitoring system fails, you lose visibility precisely when you most need it.
- **Excessive latency** — Missing latency metrics means SLOs cannot be defined or measured.
  Without percentile data, you cannot know whether users are experiencing acceptable latency.

### FaCTOR focus (what should protect against failure)

- **Fault isolation** — Logs and traces must allow operators to attribute a failure to the correct component.
  If you cannot connect a user complaint to a system event, diagnosis is impossible.
- **Timeliness** — SLI metrics must capture latency and error rate in a form that enables alerting.
  Averages and missing units make SLO measurement meaningless.
- **Capacity** — Metric and log pipelines have finite capacity.
  Unbounded cardinality or uncontrolled log volume can exhaust that capacity and take down monitoring for all services.

## Anti-Pattern Catalogue

### OP-01: Print/console.log instead of structured logging

```python
print(f"Processing order {order_id}")
console.log("Error:", err)
```

**Why it matters:** No log level (cannot filter errors from debug), no structured fields (cannot query), no correlation (cannot trace), no standard format (cannot parse).
Every print statement is a dead end during production diagnosis.
SEEMS: Misconfiguration (cannot diagnose from logs).
FaCTOR: Timeliness (cannot measure from log signals).
Typical severity: MEDIUM / L1.
Escalates to HIGH / L1 if the print is the only signal of a failure in an error path.

### OP-02: Logging entire objects

```python
logger.info("Request received", extra={"request": request.__dict__})
```

**Why it matters:** Full object serialisation risks logging PII (user data, passwords, tokens).
It also generates kilobytes of output per log line, creating log bloat and performance impact in hot paths.
SEEMS: Misconfiguration (PII exposure risk).
FaCTOR: Capacity (log volume can overwhelm log infrastructure).
Typical severity: MEDIUM / L1.
Escalates to HIGH / HYG if PII is confirmed in the serialised output (Regulated test: yes).

### OP-03: Unbounded metric cardinality

```python
metrics.histogram(
    "request_duration",
    duration,
    labels={"endpoint": path, "user_id": user.id}
)
```

**Why it matters:** Each unique label combination creates a new time series.
Using unbounded values (user ID, request path with path parameters, session ID, order ID) as metric labels will eventually exhaust the metrics backend's memory and storage, crashing the monitoring system.
SEEMS: Excessive load (amplifies monitoring infrastructure load).
FaCTOR: Capacity (monitoring system resource limits exceeded).
Typical severity: HIGH / L2.
Escalates to HYG (Total) if the metrics backend is shared across services — cardinality from this service can take down monitoring for all services.

### OP-04: Missing units on metrics

```python
metrics.histogram("request_duration", duration)
```

**Why it matters:** Without units (milliseconds, seconds, nanoseconds), dashboards and alerts are miscalibrated.
A "500ms" SLO alert may trigger on a value that is actually 500 nanoseconds, or miss a 500-second value entirely.
SEEMS: Misconfiguration (metric misinterpretation).
FaCTOR: Timeliness (SLO measurement is wrong).
Typical severity: LOW / L2.

### OP-05: Tracing only happy paths

Trace spans created for successful operations but not for error paths.
Errors do not set span status or record exception details.

**Why it matters:** The failures you most need to trace are invisible in the tracing system.
The tracing tool shows that a request started but not why it failed.
SEEMS: Misconfiguration (cannot diagnose failures from traces).
FaCTOR: Fault isolation (cannot attribute failure to the correct span).
Typical severity: MEDIUM / L2.

### OP-06: No user-to-system correlation

No way to go from a user complaint ("my request failed at 2:15pm") to the system's view of that request.
No request ID exposed to the user, no way to search by user ID and time.

**Why it matters:** Customer support tickets require manual log diving.
Incident response starts with "which request?" instead of "what happened?".
SEEMS: Misconfiguration (cannot diagnose user-reported issues).
FaCTOR: Fault isolation (cannot connect user experience to system behaviour).
Typical severity: MEDIUM / L1.

### OP-07: Averages instead of percentiles

Latency measured as a mean rather than as a histogram with percentile computation.

**Why it matters:** Averages hide tail latency.
A service with 1ms average and 10-second P99 looks healthy by average but is unacceptable for 1% of users.
SLOs based on averages are meaningless — they mask the tail experience that drives user dissatisfaction.
SEEMS: Excessive latency (tail latency is invisible).
FaCTOR: Timeliness (SLO measurement is misleading).
Typical severity: MEDIUM / L2.

## Review Checklist

When assessing the Observability pillar, work through each item in order.

1. **Logging format** -- Is structured logging used throughout? Are print statements and console.log absent from production paths? Are log levels assigned correctly (ERROR for failures, WARN for degradation, INFO for key events, DEBUG for development)?
2. **Log content safety** -- Do log statements avoid serialising full objects? Are sensitive fields (passwords, tokens, PII) explicitly excluded before logging?
3. **Metric coverage** -- Does every significant operation emit a latency histogram and error counter? Are metric names and units clearly documented in the metric registration?
4. **Metric label safety** -- Do metric labels use only bounded value sets (status code, service name, endpoint category)? Are unbounded values (user ID, order ID, session ID, full request paths) absent from labels?
5. **Trace completeness** -- Do trace spans cover both success and error paths? Do error spans set status and record exception details?
6. **User-to-system correlation** -- Can an operator go from a user-reported failure to the system event that caused it? Is a request ID or trace ID available to users and searchable in logs?
7. **Latency measurement** -- Is latency measured as a histogram (enabling P50, P95, P99 computation)? Are averages the only latency measurement used?

## Severity Framing

Severity for Observability findings is about the reliability of the observability infrastructure itself and the ability to diagnose failures.

- **Monitoring infrastructure risk** -- Unbounded cardinality and excessive log volume threaten the systems that provide visibility.
  When monitoring fails, all services become opaque simultaneously.
- **Diagnosis gap** -- Missing correlation, unstructured logs, and absent metrics increase mean time to diagnosis.
  Every gap in observability extends incidents.
- **SLO integrity** -- Averages instead of percentiles and missing units silently corrupt the metrics that SLOs and alerts depend on.
  The service may appear healthy while users experience serious degradation.
