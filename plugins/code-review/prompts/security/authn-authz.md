# Authentication & Authorisation

Can an attacker pretend to be someone else, or gain access they should not have?

The Authentication & Authorisation pillar evaluates whether identity is verified, access is controlled, and privilege is appropriately bounded.
It covers STRIDE threats **Spoofing** (impersonation) and **Elevation of Privilege** (unauthorised access), and checks the Security properties **Authenticity** and **Authorization** that defend against them.
When this pillar is weak, attackers can access other users' data, perform admin operations without being an admin, or maintain access after credentials are revoked.

## Focus Areas

### STRIDE Threats (attack lens)

- **Spoofing** — Can an attacker impersonate a user or service?
  Authentication bypass, credential theft, session hijacking, forged tokens.
- **Elevation of Privilege** — Can an attacker gain access beyond what their role permits?
  Missing authorisation checks, client-side-only access control, insecure object references.

### Security Properties (defence lens)

- **Authenticity** — Identity is verified before granting access.
  Strong authentication, credential protection, session management, token validation.
- **Authorization** — Access is restricted to what the authenticated identity is permitted.
  RBAC/ABAC enforcement, object-level access control, default-deny posture, server-side enforcement.

## Anti-Pattern Catalogue

### AA-01: Missing authentication on sensitive endpoint

```python
@app.route('/admin/users', methods=['DELETE'])
def delete_user():
    user_id = request.args.get('user_id')
    User.query.filter_by(id=user_id).delete()
```

STRIDE: Spoofing. Security property missing: Authenticity.
**Exploit scenario:** Attacker sends `DELETE /admin/users?user_id=1` with no token — operation succeeds.
Typical severity: HIGH / HYG (Irreversible — deleted users cannot be recovered without a backup restore).

### AA-02: Broken object-level authorisation (IDOR)

```python
@app.route('/api/documents/<doc_id>')
@login_required
def get_document(doc_id):
    doc = Document.query.get(doc_id)  # No ownership check
    return doc.to_dict()
```

STRIDE: Elevation of Privilege. Security property missing: Authorization.
**Exploit scenario:** Authenticated user changes `doc_id` from 42 to 43 and receives another user's document.
Typical severity: HIGH / L1. Escalates to HYG if the document contains regulated data.

### AA-03: Client-side only access control

Admin features hidden in the UI (`{isAdmin && <AdminPanel />}`) but the API endpoint has no server-side authorisation check.
STRIDE: Elevation of Privilege. Security property missing: Authorization.
**Exploit scenario:** Attacker calls `POST /api/admin/promote` directly via curl, bypassing the UI restriction entirely.
Typical severity: HIGH / L1.

### AA-04: Weak JWT validation

```python
token = jwt.decode(token_string, options={"verify_signature": False})
```

STRIDE: Spoofing. Security property missing: Authenticity.
**Exploit scenario:** Attacker crafts a JWT with `{"sub": 1, "role": "admin"}` and any signature — server accepts it.
Typical severity: HIGH / HYG (Irreversible — attacker impersonates any user including admins).

### AA-05: Hardcoded or default credentials

```python
DB_PASSWORD = "admin123"
DEFAULT_API_KEY = "changeme"
```

STRIDE: Spoofing. Security property missing: Authenticity.
**Exploit scenario:** Developer or contractor with repo access extracts the credential and authenticates to the production service.
Typical severity: HIGH / HYG (Irreversible — secret persists in git history even after removal).

### AA-06: Session not invalidated on logout

Logout handler clears the client cookie but does not invalidate the session server-side, or JWT-based auth has no revocation mechanism.
STRIDE: Spoofing. Security property missing: Authenticity.
**Exploit scenario:** Attacker captures a session cookie via XSS before the user logs out — the captured cookie remains valid indefinitely.
Typical severity: MEDIUM / L1.

### AA-07: Missing re-authentication for sensitive operations

Password change, account deletion, or financial transfer uses only the existing session — no step-up authentication required.
STRIDE: Elevation of Privilege. Security property missing: Authenticity (step-up).
**Exploit scenario:** Attacker with a hijacked session calls `POST /account/delete` — account is permanently deleted with no password challenge.
Typical severity: MEDIUM / L1. Escalates to HIGH / HYG for irreversible operations.

### AA-08: Overly permissive CORS

`Access-Control-Allow-Origin: *` combined with `Access-Control-Allow-Credentials: true`.
STRIDE: Spoofing. Security property missing: Authenticity (origin verification).
**Exploit scenario:** Attacker hosts malicious JavaScript on any domain; browser sends victim's session cookies to the API; request succeeds.
Typical severity: MEDIUM / L1.

## Review Checklist

When assessing the Authentication & Authorisation pillar, work through each item in order.

1. **Authentication coverage** — Does every sensitive endpoint enforce authentication? Are there route handlers with no session check, no token validation, and no auth middleware?
2. **Object-level authorisation** — When an endpoint accepts an object ID, does it verify the requesting user is permitted to access that specific object? Returning objects without ownership verification is IDOR.
3. **Server-side enforcement** — Are all access control decisions enforced on the server? Check for UI-only restrictions with no corresponding server-side check on the API.
4. **Token integrity** — Are JWTs validated with signature verification enabled? Are weak algorithms (`alg: none`, HS256 with guessable keys) rejected?
5. **Credential hygiene** — Are credentials absent from source code? Are defaults (admin/admin, changeme, secret) absent from configuration files?
6. **Session lifecycle** — Are sessions invalidated server-side on logout? Do tokens carry explicit expiry? Are session IDs regenerated after login?
7. **Re-authentication** — Do sensitive or irreversible operations (password change, account deletion, payment) require step-up authentication?
8. **CORS configuration** — Are CORS policies restricted to known origins? Does `allow_credentials=True` appear combined with `allow_origins=["*"]`?

## Severity Framing

Severity for Authentication & Authorisation findings is about exploitation ease and damage potential.

- **Authentication failures** — Missing auth on sensitive endpoints and accepted forged tokens are HIGH / HYG: zero-effort exploitation, immediate and irreversible impact.
- **Authorisation failures** — IDOR and missing server-side checks are HIGH / L1: require only a valid session, expose other users' data.
  Elevates to HYG when the data is regulated.
- **Session management gaps** — Persistent sessions after logout and missing re-auth are MEDIUM / L1: require prior session compromise but extend the attack window significantly.
