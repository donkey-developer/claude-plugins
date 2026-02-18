# Audit & Resilience

Can an attacker act without accountability, or exhaust the service to deny others access?

The Audit & Resilience pillar evaluates whether the application records security-relevant events with sufficient fidelity for investigation, and whether it can withstand resource-exhaustion attacks.
It covers STRIDE threats **Repudiation** (actions without evidence) and **Denial of Service** (resource exhaustion), and checks the Security properties **Non-Repudiation** and **Availability** that defend against them.
When this pillar is weak, malicious insiders can act without leaving evidence, and attackers can render the service unresponsive through crafted requests or timing attacks.

Note: the presence or absence of audit logging and rate limiting is largely binary — either the control exists or it does not.
The review focuses on completeness (are all sensitive operations covered?) and integrity (can logs be tampered with?).

## Focus Areas

### STRIDE Threats (attack lens)

- **Repudiation** — Can a user or attacker deny having performed an action?
  Sensitive operations with no audit log, logs with insufficient context, mutable audit records.
- **Denial of Service** — Can an attacker exhaust resources to make the service unavailable?
  No rate limiting on authentication, unbounded queries, no request size limits, missing timeouts on external calls, recursive processing without depth limits.

### Security Properties (defence lens)

- **Non-Repudiation** — Every security-relevant action produces an immutable, contextual audit record.
  Logs capture who, what, when, outcome. Logs are append-only or shipped to a system the application cannot modify.
- **Availability** — The service continues to function under abusive request patterns.
  Rate limiting, result pagination, request size limits, timeouts on all I/O, depth limits on recursive parsing.

## Anti-Pattern Catalogue

### AR-01: Missing audit log on sensitive operation

```python
@app.route('/api/users/<user_id>', methods=['DELETE'])
@login_required
@admin_required
def delete_user(user_id):
    User.query.filter_by(id=user_id).delete()
    db.session.commit()
    return {"status": "deleted"}, 200
```

STRIDE: Repudiation. Security property missing: Non-Repudiation.
**Exploit scenario:** A rogue admin deletes user accounts or financial records.
With no audit trail there is no record of who acted, when, or on which records — incident investigation is impossible and the action is unattributable.
Typical severity: MEDIUM / L2. Escalates to HIGH / HYG when the operation touches regulated data (health records, financial records) where audit trails are legally required.

### AR-02: Logs modifiable by application

```python
# Audit log written to a table the application user can DELETE or UPDATE
db.execute("INSERT INTO audit_log (action, user_id) VALUES (?, ?)", (action, uid))
# Or: log file in a directory the process can overwrite
logging.FileHandler('/var/app/audit.log')
```

STRIDE: Repudiation. Security property missing: Non-Repudiation.
**Exploit scenario:** An attacker who compromises the application — or a malicious insider — deletes or overwrites audit records to cover their actions.
Writable audit logs are not evidence; they are editable narratives.
Typical severity: MEDIUM / L2.

### AR-03: No rate limiting on authentication

```python
@app.route('/login', methods=['POST'])
def login():
    user = User.query.filter_by(username=request.form['username']).first()
    if user and check_password_hash(user.password_hash, request.form['password']):
        session['user_id'] = user.id
        return redirect('/dashboard')
    return render_template('login.html', error='Invalid credentials')
```

STRIDE: Denial of Service + Spoofing. Security property missing: Availability + Non-Repudiation.
**Exploit scenario:** Automated tools attempt thousands of password guesses per second per account (credential stuffing) or per IP (brute force).
Concurrently, flooding the login endpoint exhausts the database connection pool and makes the service unavailable to legitimate users.
Typical severity: MEDIUM / L1. Escalates to HIGH / HYG if account lockout is also absent and password complexity is weak (Irreversible — compromised accounts can take destructive actions).

### AR-04: Unbounded query without pagination

```python
@app.route('/api/search')
def search():
    term = request.args.get('q')
    results = Product.query.filter(Product.name.like(f"%{term}%")).all()
    return jsonify([r.to_dict() for r in results])
```

STRIDE: Denial of Service. Security property missing: Availability.
**Exploit scenario:** Attacker sends `q=%` (matches every row) — the query returns millions of records, exhausting database connections, application memory, and network bandwidth.
Repeated requests can make the service completely unresponsive.
Typical severity: HIGH / HYG (Total — single request can render the service unresponsive; no authentication required).

### AR-05: No request size limits

```python
@app.route('/api/upload', methods=['POST'])
def upload():
    data = request.get_data()   # No Content-Length check, no size cap
    process(data)
```

STRIDE: Denial of Service. Security property missing: Availability.
**Exploit scenario:** Attacker sends a 1 GB POST body — the server buffers the entire payload into memory before any application logic runs.
Multiple concurrent oversized requests exhaust server memory and bring down the process.
Typical severity: MEDIUM / L2. Escalates to HYG if the upload endpoint is unauthenticated.

### AR-06: Missing timeout on external calls

```python
response = requests.post(url, json=payload)   # No timeout parameter
result = db.execute(query)                    # No statement timeout configured
```

STRIDE: Denial of Service. Security property missing: Availability.
**Exploit scenario:** A slow or hung downstream service (network partition, overloaded database) keeps the calling thread blocked indefinitely.
Under sustained failure, all worker threads are consumed waiting on I/O — the service becomes completely unresponsive even to requests that don't touch the failing dependency.
Typical severity: HIGH / HYG (Total — in the request path; cascading failure exhausts all worker threads).

### AR-07: Recursive processing without depth limit

```python
def process(node):
    for child in node.get('children', []):
        process(child)   # No depth counter, no limit
```

STRIDE: Denial of Service. Security property missing: Availability.
**Exploit scenario:** Attacker sends a JSON or XML payload with 10,000 levels of nesting — each level adds a stack frame until a stack overflow occurs, or CPU consumption grows exponentially.
Typical severity: MEDIUM / L2. Escalates to HYG if the endpoint is public and unauthenticated.

### AR-08: Audit log missing critical context

```python
logger.info("User action performed")
logger.info(f"Deleted record")
```

STRIDE: Repudiation. Security property missing: Non-Repudiation.
**Exploit scenario:** The log proves something happened but not who did it, which record was affected, or what the outcome was.
During an incident investigation, "Deleted record" without a user ID, record ID, and timestamp with timezone is forensically useless.
Typical severity: LOW / L2.

### AR-09: Secrets or PII in audit logs

```python
logger.info(f"Login attempt: user={username}, password={password}")
logger.info(f"API request: headers={request.headers}")  # May include Authorization
```

STRIDE: Information Disclosure (cross-pillar with data-protection). Security property missing: Confidentiality.
**Exploit scenario:** Anyone with log access — log aggregation services, ops engineers, contractors — can harvest credentials or PII from audit records.
Audit logs become an attack surface rather than a security control.
Typical severity: MEDIUM / HYG (Regulated if PII; Irreversible if credentials — they must be rotated once exposed).

## Review Checklist

When assessing the Audit & Resilience pillar, work through each item in order.

1. **Audit coverage** — Do all sensitive operations (data deletion, permission changes, financial actions, admin functions) produce a structured audit log entry?
2. **Audit context** — Does each log entry capture who (user ID, service identity), what (action and target resource), when (timestamp with timezone), and outcome (success or failure with reason)?
3. **Log integrity** — Are audit logs shipped to an append-only sink (external log service, write-once storage) that the application process cannot modify or delete?
4. **Sensitive data in logs** — Are passwords, tokens, session IDs, and PII absent from log output? Are request bodies logged only after redacting sensitive fields?
5. **Authentication rate limiting** — Does the login endpoint enforce per-IP or per-user request throttling? Is there account lockout or CAPTCHA after repeated failures?
6. **Query bounds** — Do all database queries that return collections have explicit `LIMIT` or pagination? Is `.all()` without a limit absent on endpoints accessible to untrusted callers?
7. **Request size limits** — Are `Content-Length` limits or body size caps enforced on all endpoints that accept external data?
8. **I/O timeouts** — Do all HTTP client calls, database queries, and external service calls have explicit timeout parameters?
9. **Recursion limits** — Does recursive processing of external data (JSON, XML, YAML) enforce a maximum depth before rejecting the input?

## Severity Framing

Severity for Audit & Resilience findings reflects the binary nature of most controls.

- **Unbounded queries and missing timeouts** — HIGH / HYG: single requests can exhaust resources and render the service totally unresponsive.
- **Missing rate limiting on authentication** — MEDIUM / L1: enables brute force and DoS; escalates to HYG when account lockout is also absent.
- **Missing audit logs on sensitive operations** — MEDIUM / L2: escalates to HYG on regulated data where audit trails are legally required.
- **Mutable audit logs** — MEDIUM / L2: undermines all other audit controls.
- **No request size limits and unbounded recursion** — MEDIUM / L2: escalate to HYG on public unauthenticated endpoints.
- **Secrets or PII in logs** — MEDIUM / HYG: credentials require rotation once exposed (Irreversible); PII is a regulatory violation.
- **Audit log with insufficient context** — LOW / L2: the log exists but is forensically inadequate.
