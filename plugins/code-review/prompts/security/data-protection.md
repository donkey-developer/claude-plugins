## Data Protection Pillar

**Mandate:** Can attackers access data they should not see or modify data without detection?

Reviews cryptographic usage, secrets exposure, data classification, and at-rest/in-transit encryption.
If an attacker can read sensitive data or alter it undetected, confidentiality and integrity are lost.

**Tampering boundary:** Tampering is split across two pillars.
Injection (untrusted input alters behaviour) belongs to input-validation.
Data integrity (data modified at rest or in transit without detection) belongs here.
If data is modified without detection after acceptance, it is a data-protection finding.

### Focus Areas

- Secrets loaded from environment or secret manager, never hardcoded in source.
- PII masked or excluded from log output.
- Passwords hashed with a modern algorithm (bcrypt, argon2, scrypt).
- Error responses exclude stack traces, query text, and internal paths.
- TLS verification enabled on all outbound connections.
- API responses scoped to required fields — no over-fetching of sensitive data.
- Sensitive data encrypted at rest; data classified and handled according to sensitivity level.

### STRIDE / Security Property Emphasis

| STRIDE focus | Security property |
|--------------|-------------------|
| Information Disclosure | Confidentiality |
| Tampering (integrity) | Integrity |

---

## Anti-Patterns

### DP-01: Secrets in source code

API keys, passwords, tokens, or connection strings as string literals in source files.
Anyone with repo access sees them; they persist in git history even after removal.

**STRIDE:** Information Disclosure | **Property:** Confidentiality | **Typical:** HIGH / HYG (Irreversible)

### DP-02: PII in log output

`logger.info(f"User: {email}, SSN: {ssn}")` or logging entire request/response objects containing user data.
PII in logs violates GDPR, CCPA, HIPAA; logs have weaker access controls than databases.

**STRIDE:** Information Disclosure | **Property:** Confidentiality | **Typical:** MEDIUM / HYG (Regulated)

### DP-03: Broken cryptographic algorithm

`hashlib.md5(password)`, `DES.new(key)`, `AES.new(key, AES.MODE_ECB)`.
MD5/SHA-1 broken for password hashing; DES broken (56-bit key); ECB reveals patterns.

**STRIDE:** Information Disclosure | **Property:** Confidentiality | **Typical:** MEDIUM / L1 (escalates to HYG if regulated data)

### DP-04: Sensitive data in error responses

`return {"error": str(e), "query": sql_query, "stack": traceback.format_exc()}`.
Exposes database schema, file paths, dependency versions — aids attacker reconnaissance.

**STRIDE:** Information Disclosure | **Property:** Confidentiality | **Typical:** MEDIUM / L1 (escalates to HYG if credentials or PII)

### DP-05: Missing TLS verification

`requests.get(url, verify=False)`, `ssl_context.check_hostname = False`.
Enables man-in-the-middle attacks; traffic intercepted and modified without detection.

**STRIDE:** Information Disclosure + Tampering | **Property:** Confidentiality + Integrity | **Typical:** MEDIUM / L1

### DP-06: Excessive data in API responses

API returns entire database records including password hashes, internal IDs, admin flags, and PII the client does not need.
Sensitive fields visible in browser dev tools or API logs even if the UI does not display them.

**STRIDE:** Information Disclosure | **Property:** Confidentiality | **Typical:** MEDIUM / L1 (escalates to HYG if password hashes or regulated data)

### DP-07: Unencrypted sensitive data at rest

Passwords stored in plaintext, credit card numbers without encryption, health records in unencrypted columns.
Any database access (backup theft, SQL injection, insider threat) exposes all sensitive data.

**STRIDE:** Information Disclosure | **Property:** Confidentiality | **Typical:** HIGH / HYG (Regulated)

---

## Review Checklist

A "no" answer is a potential finding; investigate before raising it.

- Are secrets loaded from environment variables or a secret manager, with no hardcoded values in source?
- Is PII masked or excluded from log output?
- Are passwords hashed with a modern algorithm (bcrypt, argon2, scrypt)?
- Do error responses exclude stack traces, query text, and internal paths?
- Is TLS verification enabled on all outbound connections?
- Do API responses return only the fields the client needs, with no over-fetching of sensitive data?
- Is sensitive data encrypted at rest (passwords hashed, PII and regulated data encrypted)?
- Is data classified and handled according to its sensitivity level?

### Maturity Mapping

- **L1 (1.3):** Secrets loaded from environment or external store, not source.
- **L1:** Sensitive data encrypted at rest; passwords hashed with a modern algorithm.
- **L2 (2.4):** Error responses do not leak internal state or stack traces.
- **L2:** API responses scoped to required fields; PII excluded from log output.
