# Anti-Patterns Catalogue — Security Domain

> Complete catalogue of code patterns that Security reviewers should flag. Organised by pillar, with STRIDE classification and typical severity.

## How to use this document

Each anti-pattern includes:
- **Pattern name** — a short, memorable label
- **What it looks like** — concrete code description
- **Why it's bad** — exploitation impact
- **STRIDE category** — which threat it enables
- **Typical severity** — default assessment (may be higher or lower depending on context)

When adding new anti-patterns to prompts, follow this structure. Use concrete descriptions with exploit scenarios, not abstract categories.

---

## Authentication & Authorization Pillar Anti-Patterns

### AA-01: Missing authentication on sensitive endpoint

**What it looks like:** Route handler for a sensitive operation (user data, admin functions, financial actions) with no `@login_required`, no auth middleware, no token check.

**Why it's bad:** Any unauthenticated user can perform the operation. If the endpoint is publicly reachable, the attack requires zero effort.

**STRIDE:** Spoofing (no identity verification)
**Typical severity:** HIGH / HYG (Irreversible if the operation is destructive)

### AA-02: Broken object-level authorization (IDOR)

**What it looks like:** Endpoint accepts an object ID (user_id, doc_id, order_id) and returns/modifies the object without verifying the requesting user has access.

**Why it's bad:** Authenticated users can access or modify any object by iterating or guessing IDs. Data belonging to other users is exposed.

**STRIDE:** Elevation of Privilege (accessing other users' data)
**Typical severity:** HIGH / L1 (escalates to HYG if the data is regulated — health, financial)

### AA-03: Client-side only access control

**What it looks like:** Admin features hidden by UI elements (`v-if="isAdmin"`, `{isAdmin && <AdminPanel/>}`) but the API endpoints have no server-side authorization check.

**Why it's bad:** Any user who calls the API directly (curl, Postman, browser dev tools) bypasses the UI restriction entirely.

**STRIDE:** Elevation of Privilege (UI-only access control)
**Typical severity:** HIGH / L1

### AA-04: Weak JWT validation

**What it looks like:** `jwt.decode(token, options={"verify_signature": False})` or accepting `alg: none` tokens.

**Why it's bad:** Attacker forges a JWT with arbitrary claims (any user_id, any role, any permissions). Complete identity takeover.

**STRIDE:** Spoofing (forged identity token)
**Typical severity:** HIGH / HYG (Irreversible — attacker can take any action as any user)

### AA-05: Hardcoded or default credentials

**What it looks like:** `DB_PASSWORD = "admin123"`, `DEFAULT_API_KEY = "changeme"`, or credentials in Docker Compose files without override.

**Why it's bad:** Default credentials are the first thing attackers try. Tools like Shodan and Censys scan for services with known defaults.

**STRIDE:** Spoofing (trivial authentication bypass)
**Typical severity:** HIGH / HYG (Irreversible — once credentials are known, attacker has full access)

### AA-06: Session not invalidated on logout

**What it looks like:** Logout handler clears the client cookie but doesn't invalidate the session on the server. Or JWT-based auth with no revocation mechanism.

**Why it's bad:** A stolen session token remains valid even after the user "logs out". If the token was captured (XSS, network sniffing), the attacker maintains access indefinitely.

**STRIDE:** Spoofing (persistent session hijacking)
**Typical severity:** MEDIUM / L1

### AA-07: Missing re-authentication for sensitive operations

**What it looks like:** Password change, email change, or account deletion uses only the existing session — no password confirmation or MFA step.

**Why it's bad:** A session-hijacked attacker can permanently take over the account by changing credentials. The legitimate user loses access.

**STRIDE:** Elevation of Privilege (session-to-account takeover)
**Typical severity:** MEDIUM / L1 (escalates to HIGH / HYG if the operation is irreversible — account deletion)

### AA-08: Overly permissive CORS

**What it looks like:** `Access-Control-Allow-Origin: *` combined with `Access-Control-Allow-Credentials: true`.

**Why it's bad:** Any website can make authenticated requests to the API on behalf of the user. Enables cross-site data theft.

**STRIDE:** Spoofing (cross-origin request forgery enabling identity abuse)
**Typical severity:** MEDIUM / L1

---

## Data Protection Pillar Anti-Patterns

### DP-01: Secrets in source code

**What it looks like:** API keys, passwords, tokens, or connection strings as string literals in source files. `AWS_KEY = "AKIA..."`, `password = "prod_pass_123"`.

**Why it's bad:** Secrets are exposed to anyone with repo access. They persist in git history even after removal. Rotation requires a code change and deploy.

**STRIDE:** Information Disclosure (secrets exposed to all repo readers)
**Typical severity:** HIGH / HYG (Irreversible — once committed, the secret is in git history permanently)

### DP-02: PII in log output

**What it looks like:** `logger.info(f"User: {email}, SSN: {ssn}")` or logging entire request/response objects that contain user data.

**Why it's bad:** PII in logs is a regulatory violation (GDPR, CCPA, HIPAA). Logs have weaker access controls than databases and are often shipped to third-party services.

**STRIDE:** Information Disclosure (PII exposed via logs)
**Typical severity:** MEDIUM / HYG (Regulated — PII exposure violates data protection law)

### DP-03: Broken cryptographic algorithm

**What it looks like:** `hashlib.md5(password)`, `DES.new(key)`, `cipher = AES.new(key, AES.MODE_ECB)`.

**Why it's bad:** MD5 and SHA1 are broken for password hashing (rainbow tables, fast GPU cracking). DES is broken (56-bit key). ECB mode reveals patterns in encrypted data.

**STRIDE:** Information Disclosure (data recoverable from weak encryption)
**Typical severity:** MEDIUM / L1 (escalates to HYG if the data is regulated)

### DP-04: Sensitive data in error responses

**What it looks like:** `return {"error": str(e), "query": sql_query, "stack": traceback.format_exc()}`.

**Why it's bad:** Error responses expose internal implementation details — database schema, file paths, dependency versions. Aids attacker reconnaissance.

**STRIDE:** Information Disclosure (internal details leaked to callers)
**Typical severity:** MEDIUM / L1 (escalates to HYG if the response contains credentials or PII)

### DP-05: Missing TLS verification

**What it looks like:** `requests.get(url, verify=False)`, `ssl_context.check_hostname = False`.

**Why it's bad:** Disabling TLS verification enables man-in-the-middle attacks. An attacker on the network can intercept and modify all traffic.

**STRIDE:** Information Disclosure + Tampering (traffic intercepted and modified)
**Typical severity:** MEDIUM / L1

### DP-06: Excessive data in API responses

**What it looks like:** API returns entire database records including fields the client doesn't need — password hashes, internal IDs, admin flags, PII.

**Why it's bad:** Over-fetching exposes sensitive fields to any client. Even if the UI doesn't display them, they're visible in browser dev tools or API logs.

**STRIDE:** Information Disclosure (unnecessary data exposure)
**Typical severity:** MEDIUM / L1 (escalates to HYG if password hashes or regulated data are included)

### DP-07: Unencrypted sensitive data at rest

**What it looks like:** Passwords stored in plaintext. Credit card numbers stored without encryption. Health records in unencrypted database columns.

**Why it's bad:** Any database access (backup theft, SQL injection, insider threat) exposes all sensitive data. Regulatory violation for PCI-DSS, HIPAA, GDPR.

**STRIDE:** Information Disclosure (data exposed if storage is compromised)
**Typical severity:** HIGH / HYG (Regulated — plaintext storage of regulated data)

---

## Input Validation Pillar Anti-Patterns

### IV-01: SQL injection via string concatenation

**What it looks like:** `f"SELECT * FROM users WHERE id = {user_id}"` or `"SELECT * FROM users WHERE name = '" + name + "'"`.

**Why it's bad:** Attacker controls the SQL query. Can extract all data (`UNION SELECT`), modify data (`UPDATE/DELETE`), or execute OS commands on some databases (`xp_cmdshell`).

**STRIDE:** Tampering (injection)
**Typical severity:** HIGH / HYG (Irreversible — data breach or modification)

### IV-02: Command injection via shell execution

**What it looks like:** `os.system(f"convert {filename} output.png")` or `subprocess.call(cmd, shell=True)` with user input.

**Why it's bad:** Attacker achieves remote code execution. Can read files, exfiltrate data, install backdoors, pivot to other systems.

**STRIDE:** Tampering (injection)
**Typical severity:** HIGH / HYG (Irreversible — arbitrary code execution)

### IV-03: XSS via unsafe rendering

**What it looks like:** `dangerouslySetInnerHTML`, `v-html`, `|safe` filter, `raw()`, `<%- %>` with user content.

**Why it's bad:** Attacker injects JavaScript that runs in other users' browsers. Can steal session cookies, redirect users, deface the page, or perform actions as the victim.

**STRIDE:** Tampering (injection)
**Typical severity:** HIGH / L1 (escalates to HYG if sessions are not HttpOnly or if the application handles regulated data)

### IV-04: Path traversal

**What it looks like:** `file_path = f"/uploads/{user_filename}"` followed by `open(file_path)` or `send_file(file_path)`.

**Why it's bad:** Attacker sends `../../../etc/passwd` to read arbitrary files. Can access source code, configuration files, credentials, or other users' uploads.

**STRIDE:** Tampering (injection) + Information Disclosure
**Typical severity:** HIGH / L1 (escalates to HYG if the file system contains credentials or regulated data)

### IV-05: Unsafe deserialization

**What it looks like:** `pickle.loads(request.data)`, `marshal.loads()`, `yaml.load(data)` without safe loader.

**Why it's bad:** Pickle and marshal execute arbitrary code by design. YAML without safe_load can instantiate arbitrary Python objects. No input validation can make these safe.

**STRIDE:** Tampering (injection)
**Typical severity:** HIGH / HYG (Irreversible — arbitrary code execution)

### IV-06: Template injection

**What it looks like:** `render_template_string(f"<h1>{user_input}</h1>")` or user input in Jinja2/Twig/Freemarker templates.

**Why it's bad:** Attacker sends `{{7*7}}` to test, then `{{config.items()}}` to read config, then `{{''.__class__.__mro__[1].__subclasses__()}}` for RCE.

**STRIDE:** Tampering (injection)
**Typical severity:** HIGH / HYG (Irreversible — leads to RCE in most template engines)

### IV-07: eval/exec with user input

**What it looks like:** `eval(user_expression)`, `exec(user_code)`, `Function(user_string)()` in JavaScript.

**Why it's bad:** Direct code execution. The attacker's input IS the program. No sanitisation can make this safe.

**STRIDE:** Tampering (injection)
**Typical severity:** HIGH / HYG (Irreversible — arbitrary code execution)

### IV-08: Regex with user input (ReDoS)

**What it looks like:** `re.match(user_pattern, data)` or regex with nested quantifiers like `(a+)+`.

**Why it's bad:** Crafted input causes exponential backtracking, blocking the thread for seconds to minutes. A form of algorithmic complexity attack.

**STRIDE:** Tampering (injection) — input alters execution time
**Typical severity:** MEDIUM / L2 (escalates to HYG if in request path without timeout — Total)

### IV-09: XML external entity injection (XXE)

**What it looks like:** XML parsing with external entity resolution enabled. `etree.parse(user_xml)` without disabling DTD processing.

**Why it's bad:** Attacker includes `<!DOCTYPE foo [<!ENTITY xxe SYSTEM "file:///etc/passwd">]>` to read arbitrary files or make SSRF requests.

**STRIDE:** Tampering (injection) + Information Disclosure
**Typical severity:** HIGH / L1 (escalates to HYG if the server can reach internal networks — SSRF)

### IV-10: Client-side only validation

**What it looks like:** Input validation in JavaScript/React/Vue but no corresponding server-side validation. Form max-length in HTML but no backend check.

**Why it's bad:** All client-side validation is bypassable. An attacker uses curl, Postman, or browser dev tools to send arbitrary data directly to the API.

**STRIDE:** Tampering (validation bypass)
**Typical severity:** MEDIUM / L1 (severity depends on what the validation was protecting)

---

## Audit & Resilience Pillar Anti-Patterns

### AR-01: Missing audit log on sensitive operation

**What it looks like:** Data deletion, permission changes, or financial transactions with no logging of who, what, when, why.

**Why it's bad:** No accountability. Malicious insiders or compromised accounts can act without leaving evidence. Incident investigation is impossible.

**STRIDE:** Repudiation (actions are undeniable... except they're not being recorded)
**Typical severity:** MEDIUM / L2 (escalates to HYG if the operation is on regulated data — Regulated)

### AR-02: Logs modifiable by users

**What it looks like:** Audit logs stored in a database table writable by the application user, or log files in a directory the application process can modify.

**Why it's bad:** An attacker who compromises the application can delete or modify audit logs to cover their tracks.

**STRIDE:** Repudiation (evidence can be destroyed)
**Typical severity:** MEDIUM / L2

### AR-03: No rate limiting on authentication

**What it looks like:** Login endpoint accepts unlimited requests. No per-IP or per-user throttling. No CAPTCHA after failed attempts.

**Why it's bad:** Enables brute-force password guessing. Automated tools can attempt thousands of passwords per second.

**STRIDE:** Denial of Service + Spoofing (resource exhaustion + credential compromise)
**Typical severity:** MEDIUM / L1

### AR-04: Unbounded query without pagination

**What it looks like:** `SELECT * FROM table WHERE condition` with `.all()` and no `LIMIT`, on an endpoint without authentication.

**Why it's bad:** Single request can return millions of rows, exhausting database connections and application memory. Trivial DoS.

**STRIDE:** Denial of Service (resource exhaustion)
**Typical severity:** HIGH / HYG (Total — can render the service unresponsive)

### AR-05: No request size limits

**What it looks like:** API accepts POST requests with no `Content-Length` limit or body size validation.

**Why it's bad:** Attacker sends a 1GB POST body, consuming memory and bandwidth. Multiple concurrent large requests exhaust server resources.

**STRIDE:** Denial of Service (resource exhaustion)
**Typical severity:** MEDIUM / L2

### AR-06: Missing timeout on external calls

**What it looks like:** `requests.post(url, json=payload)` with no `timeout` parameter. Database queries with no statement timeout.

**Why it's bad:** A hung dependency blocks the calling thread indefinitely. Under failure, all worker threads can be consumed, making the service completely unresponsive.

**STRIDE:** Denial of Service (resource exhaustion via blocking)
**Typical severity:** HIGH / HYG (Total — if in the request path)

### AR-07: Recursive processing without depth limit

**What it looks like:** JSON/XML parsing without depth limits. Recursive data structures processed without recursion bounds.

**Why it's bad:** Attacker sends deeply nested input (e.g., 10,000 levels of JSON nesting) causing stack overflow or extreme CPU consumption.

**STRIDE:** Denial of Service (algorithmic complexity)
**Typical severity:** MEDIUM / L2

### AR-08: Audit log missing critical context

**What it looks like:** `logger.info("User action performed")` — logging that something happened but not who, what specifically, or the outcome.

**Why it's bad:** The audit log exists but is useless for investigation. "Something happened" doesn't help determine if it was legitimate.

**STRIDE:** Repudiation (evidence exists but is insufficient)
**Typical severity:** LOW / L2

### AR-09: Secrets or PII in audit logs

**What it looks like:** `logger.info(f"Login attempt: user={username}, password={password}")` or logging full request bodies that contain tokens.

**Why it's bad:** Audit logs become a security vulnerability themselves — anyone with log access can harvest credentials or PII.

**STRIDE:** Information Disclosure (sensitive data in logs — cross-pillar with data-protection)
**Typical severity:** MEDIUM / HYG (Regulated if PII, Irreversible if credentials)

---

## Adding New Anti-Patterns

When adding a new anti-pattern to this catalogue or to the prompts:

1. Give it a **short, memorable name** (not "Bad Practice #7")
2. Describe **what it looks like** in code (concrete, not abstract)
3. Explain **why it's bad** in terms of exploitation impact (not just "it's insecure")
4. Include an **exploit scenario** — how would an attacker use this?
5. Classify with **STRIDE category**
6. Assign a **typical severity** with reasoning
7. Note **boundary conditions** that would change the severity
