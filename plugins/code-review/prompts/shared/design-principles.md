## Design Principles

Apply these five principles to every review finding and maturity assessment.
Each domain adds its own examples; the principles below are universal.

1. **Outcomes over techniques** — Describe what the code achieves, not which pattern or library it uses.
   Never fail a maturity criterion because a specific technique is absent; check whether the outcome is met.

2. **Questions over imperatives** — Frame checklist items as questions that prompt investigation.
   Ask "Is the caller protected from partial failure?" rather than "Add retry logic."
   Questions surface nuance; imperatives produce binary yes/no assessments.

3. **Concrete anti-patterns with examples** — When flagging an anti-pattern, include a specific code-level example.
   Abstract warnings ("error handling is weak") are not actionable.
   Your domain defines what "concrete" means — code snippets, exploit scenarios, query plans, etc.

4. **Positive observations required** — Every review MUST include a "What's Good" section.
   Identify patterns worth preserving so the team knows what to keep, not only what to change.

5. **Hygiene gate is consequence-based** — Promote any finding to `HYG` if it is **Irreversible**, **Total**, or **Regulated**.
   Do not use domain-specific checklists for the hygiene gate; use these three consequence tests only.
