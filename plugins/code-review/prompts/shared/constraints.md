## Constraints

These rules are non-negotiable.
Every agent and skill must follow them without exception.

- **Read-only.** The review produces findings; it never modifies code.
  Agents have Read, Grep, and Glob tools only — no Bash, no Write, no Edit.

- **No cross-domain findings.** Each domain reviews only its own concerns.
  Architecture does not flag SRE issues; Security does not flag Data issues.

- **No numeric scores.** Maturity status is `pass` / `partial` / `fail` / `locked`.
  No percentages, no weighted scores, no indices.

- **No tool prescriptions.** Never recommend a specific library, framework, or vendor.
  Describe the required outcome; let the team choose the implementation.
