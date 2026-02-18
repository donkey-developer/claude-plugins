# Response

Can operators diagnose and recover from failures?

The Response pillar evaluates whether error handling, error reporting, and failure attribution give on-call engineers enough information to act without reading source code.
When this pillar is weak, every incident starts with "open the repo" instead of "read the error".

## Focus Areas

The Response pillar applies the SEEMS/FaCTOR duality through two specific lenses.

### SEEMS focus (how the code fails)

- **Misconfiguration** — Configuration errors are the number one cause of operator confusion during incidents.
  If the error message does not distinguish "wrong config" from "dependency down", mean time to recovery increases.
- **Shared fate** — When a shared dependency fails, operators need to know which dependency failed and why.
  Ambiguous failure attribution extends incidents because engineers chase the wrong service.
- **Excessive latency** — Timeout errors need context about what was being waited on and how long.
  "Request timed out" without details is useless at 3am.

### FaCTOR focus (what should protect against failure)

- **Fault isolation** — Failures must be attributed to the correct component.
  If errors propagate without source attribution, operators chase the wrong service.
- **Output correctness** — Error responses must be well-formed and follow API contracts.
  Malformed errors break client error handling and confuse automated alerting.

## Anti-Pattern Catalogue

### RP-01: Generic error message

```python
catch (e) { return { error: "An error occurred" } }
```

**Why it matters:** On-call engineers cannot distinguish a config error from a dependency failure from a code bug.
Every incident starts with "read the code" instead of "read the error".
SEEMS: Misconfiguration (cannot diagnose config errors).
FaCTOR: Fault isolation (failure not attributed to correct component).
Typical severity: MEDIUM / L1.

### RP-02: Swallowed exception

```python
except Exception:
    pass
```

**Why it matters:** The failure is invisible.
Upstream callers may believe the operation succeeded.
Data can be silently lost with no log, no metric, and no re-throw.
SEEMS: Misconfiguration (failure is undiagnosable).
FaCTOR: Output correctness (caller receives wrong signal about success or failure).
Typical severity: HIGH / HYG (Irreversible -- if the swallowed error masks data loss).

### RP-03: Stack trace in API response

```python
return {"error": traceback.format_exc()}, 500
```

**Why it matters:** Exposes internal implementation details to external callers.
May contain file paths, dependency names, or connection strings.
Unhelpful to API consumers and potentially a security risk.
SEEMS: Misconfiguration (error output misconfigured).
FaCTOR: Output correctness (error response is not well-formed).
Typical severity: MEDIUM / L1 (escalates to HYG if the stack trace contains credentials or PII).

### RP-04: Missing correlation IDs

Logs from different services or operations within a request have no shared identifier -- no request ID, no trace ID, no correlation token.

**Why it matters:** When a user reports a problem, operators cannot trace the request through the system.
Diagnosis requires time-based log correlation, which is error-prone and slow.
SEEMS: Shared fate (cross-service failure diagnosis impossible).
FaCTOR: Fault isolation (cannot attribute failure to originating component).
Typical severity: MEDIUM / L1.

### RP-05: No error classification

All errors treated the same -- no distinction between retryable (timeout, rate limit) and permanent (bad request, not found) errors.

**Why it matters:** Clients retry permanent errors (wasting resources) or give up on retryable errors (unnecessary failure).
Automated retry logic cannot make correct decisions without classification.
SEEMS: Excessive load (retrying permanent errors amplifies load).
FaCTOR: Output correctness (error semantics do not guide correct client behaviour).
Typical severity: MEDIUM / L1.

### RP-06: Errors require code reading

Error messages reference internal variable names or enum values that only make sense with access to the source code.

```
ERR_STATE_7: InvalidTransition state=PENDING_REVIEW
```

**Why it matters:** On-call engineers who did not write the code cannot understand the error without finding and reading the relevant source file.
SEEMS: Misconfiguration (cannot diagnose without code access).
FaCTOR: Fault isolation (failure diagnosis blocked by indirection).
Typical severity: LOW / L1.

## Review Checklist

When assessing the Response pillar, work through each item in order.

1. **Error message quality** -- Do error messages include what failed, where it failed, and enough context for an operator to act without reading source code?
2. **Exception handling** -- Are all exceptions either logged, re-thrown, or recorded as a metric? Are there any swallowed exceptions (`catch` with no action)?
3. **Error classification** -- Do error responses distinguish retryable errors (timeout, rate limit, transient failure) from permanent errors (bad request, not found, validation failure)?
4. **Correlation ID propagation** -- Do logs and error responses include a request ID or trace ID that can be used to follow a request across services and async boundaries?
5. **Error response format** -- Are error responses well-formed and consistent with API contracts? Are internal details (stack traces, variable names, internal enum values) excluded from responses to external callers?

## Severity Framing

Severity for Response findings is about production consequence -- specifically, what happens when an operator receives this error at 3am.

- **Error propagation** -- Does the error help or hinder diagnosis?
  Generic messages, swallowed exceptions, and missing correlation IDs all increase mean time to recovery.
- **Missing runbooks** -- Can operators act on the error without reading code?
  Errors that reference internal state, variable names, or undocumented codes force engineers into the codebase during an incident.
- **Unsafe error handling** -- Does the error handling make things worse?
  Retries on permanent errors amplify load.
  Swallowed exceptions mask data loss.
  Stack traces in responses leak internal details.
