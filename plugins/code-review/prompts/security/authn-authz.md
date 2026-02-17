## Authentication & Authorisation Pillar

**Mandate:** Can attackers impersonate users or gain access they should not have?

Reviews authentication controls, authorisation enforcement, session management, and credential handling.
If an attacker can forge an identity or escalate privileges, every other security control is irrelevant.

### Focus Areas

- Authentication enforced on all endpoints that access or modify protected resources.
- Authorisation verifies access to the specific resource (object-level, not just role-level).
- JWT tokens have signature verification enabled with a strong algorithm and key.
- Sessions have explicit expiry, server-side invalidation on logout, and re-authentication for sensitive operations.
- Credentials never hardcoded in source; defaults not shipped to production.
- CORS policies do not combine wildcard origins with credentials.

### STRIDE / Security Property Emphasis

| STRIDE focus | Security property |
|--------------|-------------------|
| Spoofing | Authenticity |
| Elevation of Privilege | Authorisation |

---

## Anti-Patterns

### AA-01: Missing authentication on sensitive endpoint

Route handler for a sensitive operation with no `@login_required`, no auth middleware, no token check.
Any unauthenticated user can perform the operation — zero-effort exploitation.

**STRIDE:** Spoofing | **Property:** Authenticity | **Typical:** HIGH / HYG (Irreversible)

### AA-02: Broken object-level authorisation (IDOR)

Endpoint accepts an object ID and returns/modifies the object without verifying the requesting user has access.
Attacker iterates or guesses IDs to access other users' data.

**STRIDE:** Elevation of Privilege | **Property:** Authorisation | **Typical:** HIGH / L1 (escalates to HYG if regulated data)

### AA-03: Client-side only access control

Admin features hidden by UI elements (`v-if="isAdmin"`, `{isAdmin && <AdminPanel/>}`) but API endpoints have no server-side authorisation.
Any user who calls the API directly bypasses the restriction.

**STRIDE:** Elevation of Privilege | **Property:** Authorisation | **Typical:** HIGH / L1

### AA-04: Weak JWT validation

`jwt.decode(token, options={"verify_signature": False})` or accepting `alg: none` tokens.
Attacker crafts a JWT with arbitrary claims — complete identity takeover for any user including admins.

**STRIDE:** Spoofing | **Property:** Authenticity | **Typical:** HIGH / HYG (Irreversible)

### AA-05: Hardcoded or default credentials

`DB_PASSWORD = "admin123"` or `DEFAULT_API_KEY = "changeme"` in source.
Default credentials are the first thing attackers try; once committed, the secret persists in git history.

**STRIDE:** Spoofing | **Property:** Authenticity | **Typical:** HIGH / HYG (Irreversible)

### AA-06: Session not invalidated on logout

Logout clears the client cookie but does not invalidate the session server-side.
A stolen token remains valid after logout — the attacker maintains access indefinitely.

**STRIDE:** Spoofing | **Property:** Authenticity | **Typical:** MEDIUM / L1

### AA-07: Missing re-authentication for sensitive operations

Password change, email change, or account deletion uses only the existing session — no password confirmation or MFA step.
A session-hijacked attacker permanently takes over the account by changing credentials.

**STRIDE:** Elevation of Privilege | **Property:** Authorisation | **Typical:** MEDIUM / L1 (escalates to HYG if irreversible)

### AA-08: Overly permissive CORS

`Access-Control-Allow-Origin: *` combined with `Access-Control-Allow-Credentials: true`.
Any website can make authenticated requests on behalf of the user, enabling cross-site data theft.

**STRIDE:** Spoofing | **Property:** Authenticity | **Typical:** MEDIUM / L1

---

## Review Checklist

A "no" answer is a potential finding; investigate before raising it.

- Does every endpoint that accesses or modifies protected resources have authentication middleware?
- Does authorisation verify the requesting user has access to the **specific resource**, not just a valid session?
- Are JWT tokens validated with signature verification enabled and a strong algorithm (RS256 or HS256 with a strong key)?
- Do sessions have explicit expiry and are they invalidated server-side on logout?
- Are credentials loaded from environment variables or a secret manager, with no hardcoded values in source?
- Do sensitive operations (password change, account deletion) require re-authentication?
- Is the CORS policy scoped to specific trusted origins when credentials are allowed?
- Is the default access posture deny-all, with access granted explicitly per endpoint?

### Maturity Mapping

- **L1 (1.1):** Authentication and authorisation applied consistently on all protected paths.
- **L1 (1.3):** Secrets loaded from environment or external store, not source.
- **L1 (1.4):** Sessions have explicit expiry and rotation.
- **L2 (2.3):** Roles default to least privilege; access granted explicitly.
