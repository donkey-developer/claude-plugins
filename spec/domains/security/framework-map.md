# Framework Map — STRIDE, Security Properties, and Pillars

> How the Security domain frameworks relate to each other. Use this map when writing or reviewing prompts to ensure coverage is complete and lenses are applied correctly.

## The Duality: STRIDE attacks, Properties defend

Every STRIDE threat category has a corresponding security property that mitigates it. When a reviewer identifies a STRIDE threat, they should recommend strengthening the corresponding security property.

| STRIDE threat | Security property | Pillar | Why this pairing |
|---------------|------------------|--------|-----------------|
| **S**poofing | **Authenticity** | authn-authz | Spoofing impersonates users; authenticity (strong authentication, credential protection) verifies identity. |
| **T**ampering | **Integrity** | input-validation + data-protection | Tampering modifies data/behaviour; integrity (input validation, checksums, parameterised queries) ensures data is unaltered. Shared across two pillars — see boundary rules below. |
| **R**epudiation | **Non-repudiability** | audit-resilience | Repudiation denies actions; non-repudiability (audit trails, tamper-evident logs) provides proof. |
| **I**nformation Disclosure | **Confidentiality** | data-protection | Information disclosure exposes secrets; confidentiality (encryption, access control, masking) keeps data hidden. |
| **D**enial of Service | **Availability** | audit-resilience | DoS disrupts service; availability (rate limiting, resource bounds, abuse prevention) maintains access. |
| **E**levation of Privilege | **Authorization** | authn-authz | Elevation grants unearned access; authorization (RBAC, least privilege, access control) restricts access. |

### Using the duality in reviews

When writing a finding:
1. Identify the **STRIDE category** (what can the attacker do?)
2. Check the **Security property** (what should protect against it?)
3. If the property is missing or insufficient, that's the finding
4. The recommendation should describe the security property to strengthen, not a specific technique

Example:
- STRIDE: Tampering (SQL injection on line 47)
- Property needed: Integrity (parameterised queries)
- Finding: "User input concatenated directly into SQL query enables arbitrary data extraction"
- Recommendation: "Use parameterised queries or prepared statements to separate data from commands"

## The Tampering Boundary

Tampering is the only STRIDE category split across two pillars. This is deliberate — injection attacks and data integrity violations are distinct concern types that require different expertise.

| Concern | Pillar owner | What to look for |
|---------|-------------|-----------------|
| **Injection** (untrusted input alters behaviour) | input-validation | SQL injection, command injection, XSS, path traversal, template injection, deserialization attacks |
| **Data integrity** (data modified at rest or in transit) | data-protection | Missing checksums, weak cryptography, unsigned data, tampered logs, unverified file uploads |

**Rule:** If malicious **input** changes the **behaviour** of the system, it's input-validation's finding. If data is **modified without detection** after it's been accepted, it's data-protection's finding.

**Overlap handling:** Both pillars may flag the same file if it both accepts unvalidated input AND stores data without integrity checks. The synthesis step deduplicates — see Section 6 of `spec.md`.

## Pillar Focus Areas

Each pillar emphasises specific STRIDE categories and security properties. This is not exclusive — any pillar can flag any category — but these are the primary focus areas that each subagent should prioritise.

### Authentication & Authorization pillar

**Mandate:** Can attackers impersonate users or gain access they shouldn't have?

| STRIDE focus | Why |
|-------------|-----|
| Spoofing | Authentication bypass is the most direct path to impersonation. Weak credentials, missing MFA, session hijacking. |
| Elevation of Privilege | Broken access control is consistently in the OWASP Top 10. IDOR, role escalation, missing authorization checks. |

| Property focus | Why |
|---------------|-----|
| Authenticity | Credential handling (hashing, transmission, storage), token security (JWT validation, session management), MFA. |
| Authorization | RBAC/ABAC correctness, default-deny posture, object-level access control, privilege inheritance. |

### Data Protection pillar

**Mandate:** Can attackers access data they shouldn't see or modify data without detection?

| STRIDE focus | Why |
|-------------|-----|
| Information Disclosure | Data breaches are among the most costly incidents. PII exposure, secrets in logs, excessive API responses. |
| Tampering (Data integrity) | Undetected data modification leads to fraud, corruption, compliance violations. Missing checksums, weak crypto. |

| Property focus | Why |
|---------------|-----|
| Confidentiality | Encryption at rest and in transit, data classification, masking in logs, data minimisation. |
| Integrity | Cryptographic signatures, database constraints, tamper-evident storage, authenticated encryption. |

### Input Validation pillar

**Mandate:** Can malicious input alter the intended behaviour of the system?

| STRIDE focus | Why |
|-------------|-----|
| Tampering (Injection) | Injection remains the most dangerous vulnerability class. SQL injection, command injection, and XSS can lead to complete system compromise. Most are trivially exploitable once found. |

| Property focus | Why |
|---------------|-----|
| Integrity (Input) | Parameterised queries, allowlist validation, output encoding, safe deserialization, template sandboxing. |

### Audit & Resilience pillar

**Mandate:** Can users deny their actions? Can attackers disrupt service availability?

| STRIDE focus | Why |
|-------------|-----|
| Repudiation | Without audit trails, incidents can't be investigated, compliance can't be proven, bad actors can't be held accountable. |
| Denial of Service | A single attacker can take down a service without rate limiting or resource bounds, affecting all users. |

| Property focus | Why |
|---------------|-----|
| Non-repudiability | Security event logging (who, what, when, where, outcome), tamper-evident log storage, cross-service correlation. |
| Availability | Rate limiting (per-user, per-IP), resource bounds (request size, query limits, timeouts), abuse prevention. |

## Coverage Matrix

This matrix shows which STRIDE categories are covered by which pillar. Use it to verify that prompt changes don't create coverage gaps.

| | Spoofing | Tampering (Injection) | Tampering (Integrity) | Repudiation | Info Disclosure | DoS | Elevation |
|---|---|---|---|---|---|---|---|
| **authn-authz** | Primary | - | - | - | - | - | Primary |
| **data-protection** | - | - | Primary | - | Primary | - | - |
| **input-validation** | - | Primary | - | - | - | - | - |
| **audit-resilience** | - | - | - | Primary | - | Primary | - |

**Key:** Primary = core focus area for this pillar. `-` = not a focus area (may still be flagged if found).

### DREAD-lite severity factors per pillar

Each pillar applies DREAD-lite factors differently based on its threat focus:

| Pillar | Damage emphasis | Exploitability emphasis | Scope emphasis |
|--------|----------------|----------------------|----------------|
| authn-authz | Full compromise, identity theft | Auth bypass difficulty, credential requirements | All users vs single user |
| data-protection | Data breach volume, data classification | Access path (public, authenticated, admin) | All data vs subset vs single record |
| input-validation | RCE, data extraction, defacement | Input vector availability, preconditions | All endpoints vs single endpoint |
| audit-resilience | Service disruption duration, evidence destruction | Resource cost to attack, automation potential | All users vs single service |

## Inter-pillar Handoffs

When a finding spans pillars, the subagent that discovers it should flag it in their own pillar's terms. The synthesis step deduplicates across pillars.

Common handoff scenarios:

| Scenario | Discovered by | Also relevant to |
|----------|---------------|------------------|
| Hardcoded API key both enables auth bypass and is a secret exposure | authn-authz or data-protection | Both — deduplicate during synthesis |
| SQL injection both enables data extraction and constitutes an injection vulnerability | input-validation | data-protection (if data classification matters) |
| Missing rate limiting on login endpoint enables both brute force and DoS | authn-authz or audit-resilience | Both — deduplicate during synthesis |
| Audit log contains PII — relevant to both repudiation and information disclosure | audit-resilience | data-protection (PII in logs) |
| Deserialization attack enables both code execution (injection) and data tampering | input-validation | data-protection (if persisted data is affected) |
