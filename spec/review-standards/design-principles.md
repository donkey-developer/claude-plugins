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
