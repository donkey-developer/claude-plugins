# Maturity Criteria — Security Domain

> Detailed criteria for each maturity level with defined "sufficient" thresholds. Use this when assessing criteria as Met / Not met / Partially met.

## Hygiene Gate

The Hygiene gate is not a maturity level — it is a promotion gate. Any finding at any level that passes any of the three tests is promoted to `HYG`.

### Test 1: Irreversible

**Question:** If this goes wrong, can the damage be undone?

**Threshold:** If exploitation would produce damage that requires more than a rollback/deploy to fix — e.g., data exfiltrated to an attacker, credentials that must be rotated across all consumers, user accounts compromised and misused, personally identifiable information leaked publicly — this is irreversible.

**Security examples that trigger this test:**
- SQL injection enabling data extraction — once data is exfiltrated, it cannot be un-leaked
- Hardcoded credentials committed to source code — once pushed, the secret is in git history and must be rotated everywhere
- Missing authentication on a destructive endpoint — deleted data cannot be recovered without backup restore
- Remote code execution via deserialization — attacker has run arbitrary code on the server
- XSS stealing session cookies where sessions persist after cookie theft — attacker's access outlasts the vulnerability fix

**Security examples that do NOT trigger this test:**
- Missing rate limiting on a non-sensitive endpoint (causes degradation, but no lasting damage)
- Weak password hashing algorithm (requires additional steps to exploit — attacker needs the hashes first)
- Missing audit logging (operational gap, but fixing it doesn't require undoing damage)

### Test 2: Total

**Question:** Can this take down the entire service or cascade beyond its boundary?

**Threshold:** If exploitation can render the service completely unresponsive or cause cascading failure beyond the attacked component — e.g., resource exhaustion via unbounded queries, thread pool starvation via missing timeouts, denial of service affecting all users — this is total.

**Security examples that trigger this test:**
- Unbounded query on a public endpoint — attacker requests `SELECT * FROM million_row_table` causing database and application memory exhaustion
- Missing timeout on external calls in the request path — one slow dependency blocks all worker threads
- ReDoS on an unauthenticated endpoint — crafted input blocks the request-handling thread pool
- No rate limiting on resource-intensive endpoint — attacker floods the service, affecting all users
- Recursive processing without depth limits — deeply nested JSON/XML causes stack overflow

**Security examples that do NOT trigger this test:**
- Rate limiting missing on a single non-critical endpoint (localised impact)
- Slow query that affects one endpoint but doesn't exhaust shared resources
- DoS that requires authentication (limits the attacker pool)

### Test 3: Regulated

**Question:** Does this violate a legal or compliance obligation?

**Threshold:** If the code would cause a breach of data protection law, financial regulation, health data requirements, or other legal obligations, this is regulated.

**Security examples that trigger this test:**
- PII (names, emails, SSNs, health data) written to log output without masking — violates GDPR, CCPA, HIPAA
- Credit card numbers stored in plaintext — PCI-DSS violation
- Health records accessible without access control — HIPAA violation
- User data shared with third-party services without consent mechanisms — GDPR violation
- Authentication data (passwords, tokens) logged in plaintext — credential exposure with regulatory implications

**Security examples that do NOT trigger this test:**
- Internal service-to-service tokens in logs (not PII, not regulated)
- Missing encryption for non-regulated internal data
- Debug endpoints exposing non-sensitive system information

---

## Level 1 — Foundations

**Overall intent:** The basics are in place. The system has authentication, validates input, and manages secrets. An attacker cannot exploit the most common vulnerability classes.

### Criterion 1.1: Authentication and authorisation are applied consistently on all protected paths

**Definition:** Every endpoint that accesses or modifies user data, performs administrative functions, or triggers state changes has authentication and authorisation checks.

**Met (sufficient):**
- Authentication middleware or decorators applied to all non-public endpoints
- Authorization checks verify the requesting user has access to the specific resource (not just "is logged in")
- Default-deny posture — new endpoints are protected unless explicitly marked as public
- Both horizontal (user A can't access user B's data) and vertical (regular users can't access admin) access controls exist

**Partially met:**
- Authentication exists on most endpoints but some sensitive endpoints are unprotected
- Authentication exists but authorization is inconsistent (some endpoints check ownership, others don't)
- Authorization exists but uses client-provided role claims without server-side verification

**Not met:**
- Sensitive endpoints with no authentication
- Authentication without authorization (all authenticated users can access everything)
- Authorization only at the UI layer, not at the API layer
- No consistent pattern — each endpoint implements its own ad-hoc auth logic

### Criterion 1.2: External input is validated before processing

**Definition:** All input from external sources (HTTP parameters, request bodies, file uploads, headers) is validated before being used in operations.

**Met (sufficient):**
- SQL queries use parameterised queries or ORM with parameter binding (no string concatenation)
- User input is never passed to shell commands, or if it is, arguments are passed as arrays with shell=False
- Output is encoded for the appropriate context (HTML encoding for web output, etc.)
- File paths from user input are canonicalised and validated against an allowlist
- Deserialization uses safe loaders (`yaml.safe_load`, JSON with size limits, no `pickle.loads` on untrusted data)

**Partially met:**
- Some input paths are validated but others are not
- ORM is used for most queries but some raw SQL with string interpolation exists
- Server-side validation exists but is incomplete (validates type but not range/format)

**Not met:**
- SQL queries built with string concatenation or f-strings
- User input passed to `os.system()`, `eval()`, or `exec()`
- No server-side validation — reliance on client-side validation only
- Deserialization of untrusted data with unsafe methods (pickle, marshal)

### Criterion 1.3: Secrets are loaded from environment or external store, not source

**Definition:** Credentials, API keys, tokens, and other secrets are not present in source code, configuration files committed to version control, or build artefacts.

**Met (sufficient):**
- Secrets loaded from environment variables, secret manager, or vault
- No string literals that look like credentials in source code
- `.env` files are in `.gitignore`
- Different credentials for dev/staging/prod environments
- Secrets are not present in Docker images or build logs

**Partially met:**
- Most secrets are externalised but some remain in configuration files
- `.env.example` exists with placeholder values but the pattern encourages local `.env` files that could be committed
- Secrets are in environment variables but are logged on application startup

**Not met:**
- API keys, passwords, or tokens as string literals in source code
- Connection strings with credentials in configuration files committed to git
- Secrets in Docker Compose files without environment variable override

### Criterion 1.4: Sessions have explicit expiry and rotation

**Definition:** User sessions have a defined lifetime, expire after inactivity, and tokens are rotated appropriately.

**Met (sufficient):**
- Session tokens or JWTs have explicit expiration times
- Inactive sessions timeout (server-side enforcement, not just client-side)
- Session tokens are regenerated after login (prevents session fixation)
- Session cookies have appropriate flags: HttpOnly, Secure, SameSite

**Partially met:**
- Tokens have expiration but no inactivity timeout
- Session regeneration on login but cookies lack security flags
- JWT expiration set but no refresh token mechanism (users re-authenticate frequently)

**Not met:**
- Sessions never expire
- No session fixation prevention (same session ID before and after login)
- Session cookies without HttpOnly or Secure flags
- JWT with no expiration claim

---

## Level 2 — Hardening

**Overall intent:** Security-hardened practices. The system has audit trails, rate limits, and least privilege defaults. Defence-in-depth is established.

**Prerequisite:** All L1 criteria must be met.

### Criterion 2.1: Security-relevant actions produce audit records

**Definition:** Actions that affect security state (authentication, authorisation, data access, data modification, admin operations) are logged with sufficient context for investigation.

**Met (sufficient):**
- Authentication events logged: login success/failure, logout, session creation
- Authorization failures logged: who tried to access what and was denied
- Data modification logged: who changed what (with old/new values masked if sensitive)
- Admin actions logged: what was done, by whom, to what target
- Logs include: actor identity, timestamp, action, target resource, outcome

**Partially met:**
- Some security events are logged but coverage is incomplete (e.g., login but not authorization failures)
- Audit logs exist but lack critical context (no actor identity, or no outcome)
- Logging exists but PII in logs is not masked

**Not met:**
- No audit logging for security events
- Sensitive operations (deletion, permission changes) have no logging
- Audit logs are generic ("action performed") without actor or resource identification

### Criterion 2.2: Exposed endpoints enforce rate limits

**Definition:** Publicly accessible endpoints have rate limiting to prevent abuse, brute force attacks, and resource exhaustion.

**Met (sufficient):**
- Authentication endpoints have rate limiting (per-IP and/or per-user)
- Resource-intensive endpoints (search, export, file upload) have rate limits
- Rate limiting is enforced server-side (not just client-side throttling)
- Rate limit responses use appropriate status codes (429) and include retry-after information

**Partially met:**
- Rate limiting exists on authentication but not on other endpoints
- Rate limiting exists but only per-IP (shared IPs can be unfairly limited, individual users on unique IPs are not limited)
- Rate limiting exists at the infrastructure level but not visible in application code

**Not met:**
- No rate limiting on any endpoint
- Authentication endpoint allows unlimited attempts
- Resource-intensive endpoints have no protection against abuse

### Criterion 2.3: Roles default to least privilege; access is granted explicitly

**Definition:** Default permissions are restrictive. Users and service accounts start with no access and are granted permissions explicitly.

**Met (sufficient):**
- New users start with minimal permissions
- Service accounts are scoped to the minimum required permissions
- Admin functions require explicit role assignment (not just "any authenticated user")
- API keys are scoped to specific operations and resources
- Permission escalation requires explicit administrative action

**Partially met:**
- Default permissions are reasonable but overly broad in some areas
- Service accounts exist but share a single set of broad permissions
- Role separation exists but admin functions are accessible to too many roles

**Not met:**
- All authenticated users have the same permissions
- Service accounts use root/admin credentials
- No role-based access control — authorization is binary (authenticated or not)
- API keys have full access with no scoping

### Criterion 2.4: Error responses do not leak internal state or stack traces

**Definition:** Error responses to clients contain enough information for the client to understand and handle the error, but do not expose internal implementation details.

**Met (sufficient):**
- Error responses use standardised error codes/messages
- Stack traces are never returned to clients (logged server-side only)
- Database query details, file paths, and internal service names are not in error responses
- Sensitive data (credentials, PII, tokens) is never in error responses
- Debug mode is disabled in production

**Partially met:**
- Most errors are sanitised but some edge cases leak details
- Stack traces are suppressed in production but debug mode can be enabled via configuration
- Error messages are generic but include internal error codes that reveal implementation details

**Not met:**
- Stack traces returned in error responses
- SQL query text, database table names, or file paths in error messages
- Credentials or PII in error responses
- Debug mode enabled in production

---

## Level 3 — Excellence

**Overall intent:** Best-in-class. Security is automated, encryption is configurable, and vulnerabilities are caught before they reach production.

**Prerequisite:** All L2 criteria must be met.

### Criterion 3.1: Security checks run automatically in the build pipeline

**Definition:** Automated security analysis is integrated into the CI/CD pipeline so that vulnerabilities are caught before deployment.

**Met (sufficient):**
- Static analysis (SAST) runs on every pull request
- Dependency scanning checks for known vulnerabilities
- Security tests are part of the CI pipeline (not just manual reviews)
- Pipeline fails or warns on critical security findings

**Partially met:**
- Some automated security checks exist but coverage is incomplete
- Security scanning runs but results are not enforced (informational only)
- Dependency scanning exists but static analysis does not (or vice versa)

**Not met:**
- No automated security checks in the pipeline
- Security review is entirely manual
- Dependency scanning is not automated

### Criterion 3.2: Encryption parameters are configurable, not hardcoded

**Definition:** Cryptographic algorithms, key sizes, and protocols can be changed without code modification (crypto-agility).

**Met (sufficient):**
- Encryption algorithms are configurable via configuration (not hardcoded in source)
- TLS versions and cipher suites are configurable
- Key rotation can be performed without code deployment
- Deprecated algorithms can be disabled via configuration

**Partially met:**
- Some encryption parameters are configurable but others are hardcoded
- Key rotation is possible but requires code changes
- Algorithm selection is configurable but the default is a weak algorithm

**Not met:**
- Encryption algorithms hardcoded in source
- Key rotation requires code change and deployment
- No ability to update cryptographic parameters without code modification

### Criterion 3.3: Dependencies are scanned for known vulnerabilities automatically

**Definition:** Third-party dependencies are continuously monitored for known security vulnerabilities.

**Met (sufficient):**
- Dependency scanning runs on every build (Dependabot, Snyk, Renovate, or equivalent)
- Critical vulnerability findings block deployment or create automated alerts
- Dependency update process is documented and followed
- Transitive dependencies are included in scanning

**Partially met:**
- Dependency scanning exists but runs periodically (not on every build)
- Scanning exists but only covers direct dependencies (not transitive)
- Alerts are generated but not systematically addressed

**Not met:**
- No automated dependency scanning
- Dependencies are updated manually and infrequently
- No process for responding to dependency vulnerabilities

### Criterion 3.4: Threat modelling is practised for significant changes

**Definition:** Significant architectural changes or new features go through a threat modelling process before implementation.

**Met (sufficient):**
- Evidence of threat modelling artefacts (threat models, DFDs, trust boundaries) in the codebase or documentation
- Threat modelling is referenced in pull request templates or review processes
- Security considerations are documented for architectural decisions

**Partially met:**
- Some threat modelling exists but is not consistent across changes
- Security considerations are discussed in PRs but not formally documented

**Not met:**
- No evidence of threat modelling
- Security is considered only reactively (after vulnerabilities are found)
