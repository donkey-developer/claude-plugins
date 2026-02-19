# Review Standards — Design Principles

> Principles that govern prompt changes across all review domains. Established in PRs #18 and #19. Each domain inherits these principles and adds domain-specific principles with domain-specific examples.

## 1. Outcomes over techniques

Maturity criteria describe **observable outcomes**, not named techniques, patterns, or libraries.

Technique names create false negatives — a team using one approach satisfies the outcome but wouldn't match a specific technique name. Outcomes are technology-neutral and verifiable from code.

**Rationale (PR #19):** Outcome-based criteria are technology-neutral and verifiable from code. Technique names exclude valid alternatives.

Each domain provides its own Good/Bad examples illustrating this principle.

## 2. Questions over imperatives

Checklists use questions to prompt investigation, not imperatives to demand compliance.

**Rationale:** Questions guide the reviewer to investigate the code and form a judgement. Imperatives produce binary "present/absent" assessments that miss nuance.

Each domain provides its own Good/Bad examples illustrating this principle.

## 3. Concrete anti-patterns with examples

Anti-pattern descriptions include specific code-level examples, not abstract categories. Each domain defines what "concrete" means in its context (code examples, exploit scenarios, SQL patterns, etc.).

## 4. Positive observations required

Every review MUST include a "What's Good" section. Reviews that only list problems are demoralising and less actionable. Positive patterns give teams confidence about what to preserve and build on.

## 5. Hygiene gate is consequence-based

The Hygiene gate uses three consequence-severity tests (Irreversible, Total, Regulated), not domain-specific checklists. This ensures consistent escalation logic across all domains.

## 6. Tool-driven discovery over content-dumping

Agents discover and read files themselves using Read, Grep, and Glob tools rather than receiving file content in their task prompt.

**Rationale (Review Scalability, #4):** Passing file content in-context creates a hard ceiling on reviewable codebase size — a moderate mono-repo (~4000-line diff, ~60 files) exhausted every agent's context window.
Manifest-driven architecture gives each agent a lightweight file inventory and lets it self-select what to read within its own context budget.
Compilation still eliminates tool overhead for prompt loading, so tools are reserved exclusively for reviewing the target codebase.
