## Response Pillar

**Mandate:** Can operators diagnose and recover from failures?

Reviews error handling, error reporting, and failure attribution.
The on-call engineer's first question at 3am is "what failed and why?"

### Focus Areas

- Error messages carry enough context to identify the failure without reading source code.
- Exceptions are never silently swallowed; every failure is visible somewhere.
- Error responses distinguish retryable from permanent failures.
- Correlation identifiers propagate across service boundaries.
- Stack traces and internal details stay out of API responses.

### SEEMS/FaCTOR Emphasis

| SEEMS focus | FaCTOR defence |
|-------------|----------------|
| Misconfiguration | Fault isolation |
| Shared fate | Fault isolation |
| Excessive load | Output correctness |

---

## Anti-Patterns

### RP-01: Generic error message

```python
except Exception as e:
    logger.error("Failed to process request")
    return {"error": "An error occurred"}, 500
```

On-call engineers cannot distinguish a config error from a dependency failure from a code bug.
Every incident starts with "read the code" instead of "read the error".

**SEEMS:** Misconfiguration | **FaCTOR:** Fault isolation | **Typical:** MEDIUM / L1

### RP-02: Swallowed exception

```python
try:
    await publish_event(order_completed)
except Exception:
    pass
```

The failure is invisible.
Callers may believe the operation succeeded; data can be silently lost.

**SEEMS:** Misconfiguration | **FaCTOR:** Output correctness | **Typical:** HIGH / HYG (Irreversible — if it masks data loss)

### RP-03: Stack trace in API response

```python
except Exception as e:
    return {"error": traceback.format_exc()}, 500
```

Exposes internal file paths, dependency names, or connection strings.
Unhelpful to consumers and harmful to operational security.

**SEEMS:** Misconfiguration | **FaCTOR:** Output correctness | **Typical:** MEDIUM / L1 (escalates to HYG if trace contains credentials or PII)

### RP-04: Missing correlation IDs

Logs across services have no shared identifier — no request ID, no trace ID, no correlation token.
Operators cannot trace a user-reported problem through the system; diagnosis falls back to slow, error-prone time-based log correlation.

**SEEMS:** Shared fate | **FaCTOR:** Fault isolation | **Typical:** MEDIUM / L1

### RP-05: No error classification

```java
catch (Exception e) {
    return new ErrorResponse("Service error");
}
```

All errors treated the same — no retryable vs permanent distinction.
Clients retry permanent errors (amplifying load) or abandon retryable ones (unnecessary failure).

**SEEMS:** Excessive load | **FaCTOR:** Output correctness | **Typical:** MEDIUM / L1

### RP-06: Errors require code reading

Error messages reference internal variable names, enum values, or opaque codes (e.g. `"ERR_STATE_7"`, `"InvalidTransition: state=PENDING_REVIEW"`).
On-call engineers cannot understand the error without reading source code, adding minutes to every incident.

**SEEMS:** Misconfiguration | **FaCTOR:** Fault isolation | **Typical:** LOW / L1

---

## Review Checklist

A "no" answer is a potential finding; investigate before raising it.

- Does each error message identify **what** failed, **where** (service and operation), and **why** (error type)?
- Are all exceptions either logged, re-thrown, counted in a metric, or routed to a dead letter queue?
- Do error responses distinguish retryable failures from permanent ones?
- Do logs and responses include a correlation identifier that follows the request across service boundaries?
- Are API error responses free of stack traces, internal paths, and raw exception details?
- When an external call times out, does the error state what dependency was called and the timeout duration?
- Can an on-call engineer understand every error message in this change without reading source code?

### Maturity Mapping

- **L1 (1.2):** Errors propagate with context sufficient for diagnosis.
- **L1 (1.3):** Timeout errors report what was being waited on and for how long.
- **L2 (2.4):** Error signals are specific enough to identify failure type and guide alert routing.
