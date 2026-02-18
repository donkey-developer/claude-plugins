# Data Protection

Can an attacker read data they should not see, or modify data they should not touch?

The Data Protection pillar evaluates whether sensitive data is properly protected from disclosure and unauthorised modification.
It covers STRIDE threats **Information Disclosure** (data exposed to unauthorised parties) and **Tampering** (data modified without authorisation), and checks the Security properties **Confidentiality** and **Integrity** that defend against them.
The Tampering threat is scoped to the code boundary — infrastructure-level tampering (network interception handled by a load balancer, storage encryption handled by the cloud provider) is out of scope unless the code explicitly disables or bypasses those controls.
When this pillar is weak, attackers can read credentials, access PII, intercept traffic, or silently corrupt stored data.

## Focus Areas

### STRIDE Threats (attack lens)

- **Information Disclosure** — Can an attacker read data they are not authorised to see?
  Secrets in source code, PII in logs, stack traces in API responses, weak encryption, unencrypted storage.
- **Tampering** — Can an attacker modify data in transit or at rest within the code boundary?
  Disabled TLS verification (enabling MITM), missing integrity checks on stored data, mutable audit records.

### Security Properties (defence lens)

- **Confidentiality** — Sensitive data is accessible only to authorised parties.
  Secrets management, data classification, encryption at rest and in transit, minimal data exposure in responses.
- **Integrity** — Data cannot be silently altered without detection.
  TLS verification enabled, integrity checks on sensitive data, immutable audit records.

## Anti-Pattern Catalogue

### DP-01: Secrets in source code

```python
AWS_SECRET_KEY = "AKIAIOSFODNN7EXAMPLE"
DB_PASSWORD = "production_p@ssw0rd!"
```

STRIDE: Information Disclosure. Security property missing: Confidentiality.
**Exploit scenario:** Developer or contractor with repo access extracts the production credential and authenticates directly to the AWS account or database — no exploitation required beyond reading the file.
Typical severity: HIGH / HYG (Irreversible — once committed, the secret exists in git history permanently; rotation requires a code change and deploy).

### DP-02: PII in log output

```python
logger.info(f"User registered: {user.email}, SSN: {user.ssn}")
```

STRIDE: Information Disclosure. Security property missing: Confidentiality.
**Exploit scenario:** Attacker or malicious insider with access to the log aggregation platform (Datadog, Splunk, ELK) extracts email addresses and SSNs; logs are retained for months and often have weaker access controls than the production database.
Typical severity: MEDIUM / HYG (Regulated — PII in logs violates GDPR, CCPA, HIPAA depending on the data type).

### DP-03: Broken cryptographic algorithm

```python
password_hash = hashlib.md5(password.encode()).hexdigest()
cipher = AES.new(key, AES.MODE_ECB)
```

STRIDE: Information Disclosure. Security property missing: Confidentiality.
**Exploit scenario:** Attacker obtains the password hash database (via SQL injection or backup theft) and recovers passwords using pre-computed rainbow tables — MD5 hashes for common passwords crack in milliseconds.
ECB mode leaks patterns in plaintext (identical blocks produce identical ciphertext), enabling data inference from encrypted records.
Typical severity: MEDIUM / L1. Escalates to HYG if the data is regulated or if a SQL injection path already exists (direct exploitation chain).

### DP-04: Sensitive data in error responses

```python
return {"error": str(e), "query": sql_query, "stack": traceback.format_exc()}
```

STRIDE: Information Disclosure. Security property missing: Confidentiality.
**Exploit scenario:** Attacker sends a malformed request to trigger an exception; the error response reveals the SQL query structure, table names, file paths, and dependency versions — providing reconnaissance data to plan a more precise attack.
Typical severity: MEDIUM / L1. Escalates to HYG if the response contains credentials or PII.

### DP-05: Disabled TLS verification

```python
requests.get(url, verify=False)
ssl_context.check_hostname = False
```

STRIDE: Information Disclosure + Tampering. Security properties missing: Confidentiality, Integrity.
**Exploit scenario:** On a shared or corporate network, attacker performs a MITM attack; because the client does not verify the server certificate, the attacker intercepts all traffic, reads API responses (Information Disclosure), and silently modifies requests (Tampering) — all without detection.
Typical severity: MEDIUM / L1.

### DP-06: Excessive data in API responses

```python
return User.query.get(user_id).to_dict()  # Returns all fields including password_hash, admin_flag
```

STRIDE: Information Disclosure. Security property missing: Confidentiality.
**Exploit scenario:** Authenticated user inspects the API response in browser dev tools and discovers their `password_hash`, `is_admin` flag, and other users' internal IDs — data not displayed in the UI but present in the JSON payload.
Typical severity: MEDIUM / L1. Escalates to HYG if password hashes or regulated data (PII, health, financial) are included.

### DP-07: Unencrypted sensitive data at rest

```python
user.credit_card = card_number  # Stored as plaintext in the database
user.ssn = social_security_number
```

STRIDE: Information Disclosure. Security property missing: Confidentiality.
**Exploit scenario:** Attacker exfiltrates the database via SQL injection or a stolen backup — all credit card numbers and SSNs are immediately readable with no additional effort required.
Typical severity: HIGH / HYG (Regulated — plaintext storage of PCI-DSS, HIPAA, or GDPR-regulated data; irreversible breach once data is exfiltrated).

## Review Checklist

When assessing the Data Protection pillar, work through each item in order.

1. **Secrets hygiene** — Are credentials, API keys, and connection strings absent from source code, config files, and test fixtures? Are secrets loaded from environment variables or a secret manager?
2. **Log content** — Do log statements avoid including PII (email, phone, national IDs), credentials, session tokens, or financial data? Is structured logging used rather than string interpolation that risks including entire objects?
3. **Cryptographic strength** — Is password hashing using bcrypt, argon2, or scrypt (not MD5, SHA1, or SHA256 without stretching)? Is symmetric encryption using AES-GCM or ChaCha20-Poly1305 (not ECB mode or DES)?
4. **Error response content** — Do error handlers return generic messages to clients? Are stack traces, SQL queries, and internal paths absent from API error responses?
5. **TLS verification** — Is certificate verification enabled for all outbound HTTP calls? Are `verify=False`, `check_hostname=False`, and `InsecureRequestWarning` suppressions absent?
6. **Response minimisation** — Do API responses include only fields the client needs? Are ORM serialisers explicitly allowlisting fields rather than serialising entire model instances?
7. **Data at rest** — Are regulated data fields (PII, payment card data, health records) encrypted at the column or application level, not just relying on disk-level encryption?
8. **Tampering boundary** — When flagging Tampering findings, confirm the issue is within the code boundary (e.g., disabled TLS verification in application code), not infrastructure handled outside the codebase.

## Severity Framing

Severity for Data Protection findings is about data sensitivity and exploitation directness.

- **Secrets in code** — HIGH / HYG: any repo reader can extract and use the credential; irreversible once committed.
- **Unencrypted regulated data** — HIGH / HYG: a database breach immediately exposes all data; regulatory violation is automatic.
- **Weak cryptography** — MEDIUM / L1: requires a secondary attack (database access) to exploit; escalates to HYG when that access is readily available.
- **PII in logs and information leakage** — MEDIUM / HYG when regulated data is involved; MEDIUM / L1 for non-regulated internal details.
- **Disabled TLS** — MEDIUM / L1: requires network position to exploit; severity increases in cloud or shared-network environments.
