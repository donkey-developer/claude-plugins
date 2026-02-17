## Observability Pillar

**Mandate:** Can we see what the system is doing in production?

Reviews logging, metrics, and tracing to ensure operators have visibility into system behaviour.
If you cannot measure it, you cannot manage it; if you cannot correlate it, you cannot debug it.

### Focus Areas

- Logging is structured with consistent fields, levels, and request correlation.
- Metrics have bounded cardinality and explicit units.
- Tracing covers both success and error paths with meaningful span attributes.
- Operators can correlate a user complaint to the system's view of that request.
- Latency is measured as distributions, not averages.

### SEEMS/FaCTOR Emphasis

| SEEMS focus | FaCTOR defence |
|-------------|----------------|
| Excessive load | Capacity |
| Excessive latency | Timeliness |
| Misconfiguration | Capacity |

---

## Anti-Patterns

### OP-01: Print/console.log instead of structured logging

```python
print(f"Processing order {order_id}")
```

No log level, no structured fields, no correlation, no standard format.
Operators cannot filter, aggregate, or alert on unstructured output.

**SEEMS:** Misconfiguration | **FaCTOR:** Timeliness | **Typical:** MEDIUM / L1

### OP-02: Logging entire objects

```python
logger.info("Request received", extra={"request": request.__dict__})
```

Risks leaking PII into logs and causes log bloat that degrades ingestion pipelines.
Performance impact in hot paths compounds the problem under load.

**SEEMS:** Misconfiguration | **FaCTOR:** Capacity | **Typical:** MEDIUM / L1 (escalates to HYG if PII is logged — Regulated)

### OP-03: Unbounded metric cardinality

```python
metrics.counter("requests_total", labels={"path": request.path, "user_id": user_id})
```

Each unique label combination creates a new time series, exhausting metrics backend memory and storage.
A single high-cardinality label can take down shared monitoring infrastructure.

**SEEMS:** Excessive load | **FaCTOR:** Capacity | **Typical:** HIGH / L2 (escalates to HYG if metrics backend is shared — Total)

### OP-04: Missing units on metrics

```python
metrics.histogram("request_duration", duration)
```

Without units, dashboards and alerts are misconfigured — seconds misread as milliseconds.
SLO alerts trigger on wrong thresholds, eroding trust in the monitoring system.

**SEEMS:** Misconfiguration | **FaCTOR:** Timeliness | **Typical:** LOW / L2

### OP-05: Tracing only happy paths

Trace spans are created for successful operations but error paths skip span creation or fail to set span status.
Failures become invisible in the tracing system, leaving operators blind to the requests that matter most.

**SEEMS:** Misconfiguration | **FaCTOR:** Fault isolation | **Typical:** MEDIUM / L2

### OP-06: No user-to-system correlation

No mechanism to go from a user complaint or support ticket to the system's view of that request.
Incident response starts with "which request?" instead of "what happened to this request?"

**SEEMS:** Misconfiguration | **FaCTOR:** Fault isolation | **Typical:** MEDIUM / L1

### OP-07: Averages instead of percentiles

```python
avg_latency = sum(durations) / len(durations)
metrics.gauge("request_latency_avg", avg_latency)
```

Averages hide tail latency; a 50ms mean can mask a 2s p99.
SLOs based on averages are meaningless because they cannot represent user-experienced performance.

**SEEMS:** Excessive latency | **FaCTOR:** Timeliness | **Typical:** MEDIUM / L2

---

## Review Checklist

A "no" answer is a potential finding; investigate before raising it.

- Does all logging use structured output with consistent fields and log levels, rather than print or console.log?
- Is PII excluded from log output, or masked where logging is unavoidable?
- Are metric label values drawn from a bounded, enumerable set (no user IDs, paths with parameters, or session IDs)?
- Do all metrics specify units explicitly (seconds, bytes, count)?
- Do trace spans cover error paths, setting span status and recording exception details?
- Can an operator trace a user-reported problem from an external identifier to the system's internal request path?
- Is latency measured using histograms that support percentile computation, rather than averages?

### Maturity Mapping

- **L1 (1.4):** Logging is structured with request correlation.
- **L2 (2.1):** SLI metrics are emitted and can measure SLOs (latency histograms, error rates, bounded cardinality).
- **L2 (2.4):** Alert-worthy signals are specific enough to identify failure type.
