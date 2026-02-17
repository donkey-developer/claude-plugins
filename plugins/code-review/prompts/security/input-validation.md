## Input Validation Pillar

**Mandate:** Can malicious input alter the intended behaviour of the system?

Reviews injection defences, deserialisation safety, file upload handling, and input-driven denial of service.
If an attacker can inject commands, queries, or markup through untrusted input, integrity of the system is compromised.

**Tampering boundary:** Injection (untrusted input alters behaviour) belongs here.
Data integrity (data modified at rest or in transit without detection) belongs to data-protection.

**Framework awareness:** ORMs, template engines with auto-escaping, and frameworks with built-in CSRF/XSS protection may mitigate some patterns.
The reviewer should verify whether the framework handles validation rather than assuming it does not.

### Focus Areas

- All external input validated, typed, and constrained before processing.
- SQL queries use parameterised queries or ORM with parameter binding — never string concatenation.
- User input never passed to shell commands, or arguments passed as arrays with `shell=False`.
- Output encoded for the appropriate context (HTML, JavaScript, URL, CSS).
- File paths canonicalised and validated against an allowlist; deserialisation uses safe loaders.
- Regular expressions from user input bounded or avoided; no catastrophic backtracking.

### STRIDE / Security Property Emphasis

| STRIDE focus | Security property |
|--------------|-------------------|
| Tampering (injection) | Integrity (input) |
| Denial of Service | Availability |

---

## Anti-Patterns

### IV-01: SQL injection via string concatenation

`f"SELECT * FROM users WHERE id = {user_id}"` — attacker supplies `1 OR 1=1` to dump tables or `; DROP TABLE` to destroy data.

**STRIDE:** Tampering | **Property:** Integrity | **Typical:** HIGH / HYG (Irreversible)

### IV-02: Command injection via shell execution

`os.system(f"convert {filename}")` or `subprocess.run(cmd, shell=True)` with user input.
Attacker appends `; rm -rf /` or pipes to a reverse shell — full system compromise.

**STRIDE:** Tampering | **Property:** Integrity | **Typical:** HIGH / HYG (Irreversible)

### IV-03: XSS via unsafe rendering

`innerHTML = userInput`, `dangerouslySetInnerHTML`, or `| safe` filter with unescaped user data.
Attacker injects JavaScript that steals sessions or performs actions as the victim.

**STRIDE:** Tampering | **Property:** Integrity | **Typical:** HIGH / L1

### IV-04: Path traversal

`open(f"/uploads/{filename}")` without canonicalisation — attacker sends `../../etc/passwd` to read arbitrary files.

**STRIDE:** Tampering | **Property:** Integrity | **Typical:** HIGH / L1

### IV-05: Unsafe deserialisation

`pickle.loads(user_data)`, `yaml.load(data)` without `SafeLoader`, or Java `ObjectInputStream` on untrusted input.
Attacker crafts a payload that executes arbitrary code during deserialisation.

**STRIDE:** Tampering | **Property:** Integrity | **Typical:** HIGH / HYG (Irreversible)

### IV-06: Template injection

User input interpolated into a server-side template: `render_template_string(user_input)`.
Attacker injects `{{config}}` to read secrets or execute code on the server.

**STRIDE:** Tampering | **Property:** Integrity | **Typical:** HIGH / HYG (Irreversible)

### IV-07: eval/exec with user input

`eval(user_expr)`, `exec(user_code)`, or `new Function(userInput)` with attacker-controlled input.
Equivalent to remote code execution — attacker runs arbitrary code in the application context.

**STRIDE:** Tampering | **Property:** Integrity | **Typical:** HIGH / HYG (Irreversible)

### IV-08: Regex with user input — ReDoS

User-supplied pattern or static regex with catastrophic backtracking on adversarial input — exponential matching time consumes CPU and blocks the event loop.

**STRIDE:** Denial of Service | **Property:** Availability | **Typical:** MEDIUM / L2

### IV-09: XML external entity injection — XXE

XML parser with external entity processing enabled on untrusted input — attacker references local files or internal URLs to exfiltrate data.

**STRIDE:** Tampering | **Property:** Integrity | **Typical:** HIGH / L1

### IV-10: Client-side only validation

Input validated in the browser (HTML `required`, JavaScript regex) but no server-side check.
Attacker bypasses the client with `curl` or a proxy — all constraints are void.

**STRIDE:** Tampering | **Property:** Integrity | **Typical:** MEDIUM / L1

---

## Review Checklist

A "no" answer is a potential finding; investigate before raising it.

- Is all external input validated, typed, and constrained on the server side before processing?
- Do SQL queries use parameterised queries or ORM parameter binding, with no string concatenation?
- Is user input excluded from shell commands, or passed as arrays with `shell=False`?
- Is output encoded for the appropriate context (HTML, JavaScript, URL) before rendering?
- Are file paths canonicalised and validated against an allowlist of permitted directories?
- Does deserialisation use safe loaders, with no `pickle`, `yaml.load`, or `ObjectInputStream` on untrusted data?
- Are regular expressions bounded against catastrophic backtracking, and is user-supplied regex avoided?
- Is XML parsing configured with external entity processing disabled?

### Maturity Mapping

- **L1 (1.2):** External input validated before processing; SQL queries parameterised.
- **L1 (1.2):** User input excluded from shell commands or passed as arrays with `shell=False`.
- **L1 (1.2):** Output encoded for context; file paths canonicalised; deserialisation uses safe loaders.
- **L2:** Regex patterns bounded; user-supplied regex avoided or sandboxed.
