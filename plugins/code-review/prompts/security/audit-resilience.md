## Audit & Resilience Pillar

**Mandate:** Can attackers act without accountability or render the system unavailable?

Reviews audit logging, rate limiting, timeouts, resource bounds, and error handling for information leakage.
If an attacker can perform sensitive operations without leaving evidence, or exhaust resources to deny service, non-repudiability and availability are lost.

**Binary checklist nature:** Most findings in this pillar are present/absent — rate limiting is enforced or it is not; audit logging records the operation or it does not.
This makes the pillar well suited to a checklist-style review.

**Cross-pillar boundaries:** AR-09 (secrets/PII in audit logs) overlaps with data-protection — log content belongs here; data classification belongs there.
AR-03 (rate limiting on authentication) overlaps with authn-authz — missing authentication belongs there; unbounded volume belongs here.

### Focus Areas

- Security-relevant actions (login, permission change, data deletion) produce audit records with who, what, when, and outcome.
- Audit logs are append-only or written to a store the application cannot modify.
- Exposed endpoints enforce rate limits, especially authentication and registration.
- Database queries use pagination or result limits; no unbounded `.all()` calls.
- Inbound request body size is constrained by the framework or middleware.
- External calls (HTTP, database, message queue) have explicit timeouts.
- Recursive or nested input processing has a depth or iteration limit.
- Error responses do not leak stack traces, internal paths, or query text.

### STRIDE / Security Property Emphasis

| STRIDE focus | Security property |
|--------------|-------------------|
| Repudiation | Non-repudiability |
| Denial of Service | Availability |

---

## Anti-Patterns

### AR-01: Missing audit log on sensitive operation

Data deletion, permission changes, or financial transactions with no logging of who, what, when, or outcome.
Malicious insiders or compromised accounts act without leaving evidence; incident investigation is impossible.

**STRIDE:** Repudiation | **Property:** Non-repudiability | **Typical:** MEDIUM / L2 (escalates to HYG if regulated data)

### AR-02: Logs modifiable by users

Audit logs stored in a database table writable by the application user, or log files in a directory the application process can modify.
An attacker who compromises the application can delete or alter logs to cover their tracks.

**STRIDE:** Repudiation | **Property:** Non-repudiability | **Typical:** MEDIUM / L2

### AR-03: No rate limiting on authentication

Login endpoint accepts unlimited requests with no per-IP or per-user throttling and no CAPTCHA after failed attempts.
Enables brute-force password guessing at thousands of attempts per second.
*(Cross-pillar: authentication bypass belongs to authn-authz; unbounded volume belongs here.)*

**STRIDE:** DoS + Spoofing | **Property:** Availability + Authenticity | **Typical:** MEDIUM / L1

### AR-04: Unbounded query without pagination

`SELECT * FROM table` with `.all()` and no `LIMIT`, on an endpoint exposed to clients.
A single request returns millions of rows, exhausting database connections and application memory — trivial denial of service.

**STRIDE:** DoS | **Property:** Availability | **Typical:** HIGH / HYG (Total)

### AR-05: No request size limits

API accepts POST requests with no `Content-Length` limit or body size validation.
Attacker sends a multi-gigabyte body, consuming memory and bandwidth; concurrent large requests exhaust server resources.

**STRIDE:** DoS | **Property:** Availability | **Typical:** MEDIUM / L2

### AR-06: Missing timeout on external calls

`requests.post(url, json=payload)` with no `timeout` parameter, or database queries with no statement timeout.
A hung dependency blocks the calling thread indefinitely; under failure, all worker threads are consumed and the service becomes unresponsive.

**STRIDE:** DoS | **Property:** Availability | **Typical:** HIGH / HYG (Total)

### AR-07: Recursive processing without depth limit

JSON/XML parsing or recursive data structures processed without depth or iteration bounds.
Attacker sends deeply nested input (e.g., 10,000 levels of JSON nesting) causing stack overflow or extreme CPU consumption.

**STRIDE:** DoS | **Property:** Availability | **Typical:** MEDIUM / L2

### AR-08: Audit log missing critical context

`logger.info("User action performed")` — the log records that something happened but not who, what specifically, or the outcome.
The audit trail exists but is useless for investigation.

**STRIDE:** Repudiation | **Property:** Non-repudiability | **Typical:** LOW / L2

### AR-09: Secrets or PII in audit logs

`logger.info(f"Login attempt: user={username}, password={password}")` or logging full request bodies that contain tokens.
Audit logs become a vulnerability — anyone with log access can harvest credentials or PII.
*(Cross-pillar: log content belongs here; data classification and encryption belong to data-protection.)*

**STRIDE:** Information Disclosure | **Property:** Confidentiality | **Typical:** MEDIUM / HYG (Regulated if PII)

---

## Review Checklist

A "no" answer is a potential finding; investigate before raising it.

- Do security-relevant actions (login, permission change, data deletion) produce audit records with who, what, when, and outcome?
- Are audit logs written to an append-only store or one the application cannot modify?
- Do exposed endpoints enforce rate limits, especially authentication and registration?
- Are database queries bounded with pagination or result limits, with no unbounded `.all()` calls?
- Is inbound request body size constrained by the framework or middleware?
- Do all external calls (HTTP, database, message queue) have explicit timeouts?
- Is recursive or nested input processing bounded by a depth or iteration limit?
- Do error responses exclude stack traces, internal paths, and query text?
- Are audit logs free of secrets, tokens, and PII?

### Maturity Mapping

- **L2 (2.1):** Security-relevant actions produce audit records with sufficient context for investigation.
- **L2 (2.2):** Exposed endpoints enforce rate limits; authentication endpoints throttled per-IP or per-user.
- **L2:** External calls have explicit timeouts; queries are paginated; request size is bounded.
