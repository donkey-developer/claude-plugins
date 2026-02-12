# Architecture Domain Specification

> Canonical reference for building, improving, and maintaining the Architecture review domain within the donkey-dev Claude Code plugin.

## 1. Purpose

The Architecture review domain evaluates code changes through the lens of structural design. It answers one question: **"If we build this, will it age well?"**

The domain produces a structured maturity assessment that tells engineering leaders:
- What structural damage is accumulating (Hygiene failures)
- What design foundations are missing (L1 gaps)
- What architectural maturity looks like for this codebase (L2 criteria)
- What excellence would require (L3 aspirations)

Architecture focuses on **design-time decisions** — the choices that determine how easy the system is to understand, change, test, and extend. It complements the SRE domain (run-time behaviour), Security domain (threat exposure), and Data domain (data product quality).

## 2. Audience

| Who | Uses the spec for |
|-----|-------------------|
| **Autonomous coding agents** | Building/modifying prompt files, agent definitions, skill orchestrators |
| **Human prompt engineers** | Reviewing agent output, calibrating severity, refining checklists |
| **Plugin consumers** | Understanding what the Architecture review evaluates and why |

## 3. Conceptual Architecture

The Architecture domain is built from three interlocking layers:

```
+----------------------------------------------+
|     C4-Inspired Zoom Levels (Structure)       |   Organises WHAT to review
|  Code . Service . System . Landscape          |   at increasing scope
+----------------------------------------------+
|    Design Principles  <-->  Erosion Patterns  |   Analytical LENSES
|    "What should this       "How does this     |
|     look like?"             go wrong?"        |
+----------------------------------------------+
|         Maturity Model (Judgement)             |   Calibrates SEVERITY
|    Hygiene --> L1 --> L2 --> L3                |   and PRIORITY
+----------------------------------------------+
```

- **Zoom Levels** provide the structural decomposition (4 levels, 4 subagents). Each level examines the system at a different scope — from individual modules to ecosystem-wide integration.
- **Design Principles** and **Erosion Patterns** provide the analytical duality. Principles describe what good architecture looks like; erosion patterns describe how architecture degrades. See `framework-map.md` for the complete mapping.
- **The Maturity Model** provides the judgement framework for prioritising findings.

These layers are defined in detail in the companion files:
- `glossary.md` — canonical definitions
- `framework-map.md` — how zoom levels, frameworks, and principles relate to each other
- `maturity-criteria.md` — detailed criteria with "sufficient" thresholds
- `calibration.md` — worked examples showing severity judgement
- `anti-patterns.md` — concrete code smells per zoom level
- `references.md` — source attribution

## 4. File Layout

The Architecture domain manifests as these files within the plugin:

```
donkey-dev/
  agents/
    arch-code.md               # Subagent: SOLID, DDD tactical, testability
    arch-service.md            # Subagent: bounded contexts, layering, deployability
    arch-system.md             # Subagent: stability patterns, API contracts, coupling
    arch-landscape.md          # Subagent: integration patterns, context maps, ADRs
  prompts/architecture/
    _base.md                   # Shared context: zoom levels, glossary, maturity model, output format
    code.md                    # Code zoom level checklist
    service.md                 # Service zoom level checklist
    system.md                  # System zoom level checklist
    landscape.md               # Landscape zoom level checklist
  skills/
    review-arch/SKILL.md       # Orchestrator: scope, parallel dispatch, synthesis, output
```

### Composition rules

1. **Each agent file is self-contained.** It embeds the full content of `_base.md` + its zoom-level prompt. Agents do not reference external files at runtime — all context must be inlined.
2. **Prompts are the source of truth.** The `prompts/architecture/` directory contains the human-readable, LLM-agnostic checklists. Agent files are compiled from these.
3. **The skill orchestrator dispatches and synthesises.** It does not contain review logic — that lives in the agents.

### When modifying files

| Change type | Files to update |
|-------------|-----------------|
| Add/change a checklist item | `prompts/architecture/<level>.md` then recompile the corresponding `agents/arch-<level>.md` |
| Change shared context (severity, maturity, output format) | `prompts/architecture/_base.md` then recompile ALL 4 agent files |
| Change orchestration logic | `skills/review-arch/SKILL.md` only |
| Add a new zoom level | New prompt file, new agent file, update SKILL.md to spawn 5th agent |

## 5. Design Principles

These principles govern all prompt changes in the Architecture domain. They align with the cross-domain principles established in PRs #18 and #19 and must be preserved.

### 5.1 Outcomes over techniques

Maturity criteria describe **observable outcomes**, not named techniques, patterns, or libraries.

| Bad (technique) | Good (outcome) |
|-----------------|----------------|
| "Uses DDD" | "Module boundaries are explicit with defined public interfaces" |
| "Implements Clean Architecture" | "Dependencies flow inward — infrastructure depends on domain, not vice versa" |
| "Has circuit breakers" | "External dependencies have failure isolation" |
| "Uses ADRs" | "Design decisions are documented with rationale and trade-offs" |
| "Follows SOLID" | "Components can be tested in isolation" |

**Rationale (PR #19):** Technique names create false negatives — a team using hexagonal architecture satisfies "dependencies flow inward" but wouldn't match "implements Clean Architecture". Outcomes are technology-neutral and verifiable from code.

### 5.2 Questions over imperatives

Checklists use questions to prompt investigation, not imperatives to demand compliance.

| Bad (imperative) | Good (question) |
|-------------------|-----------------|
| "Apply dependency inversion" | "Does business logic import infrastructure (database, HTTP, filesystem)?" |
| "Document architectural decisions" | "Are significant decisions documented with rationale?" |
| "Use bounded contexts" | "Does each service serve one cohesive domain concept?" |

**Rationale:** Questions guide the reviewer to investigate the code and form a judgement. Imperatives produce binary "present/absent" assessments that miss nuance.

### 5.3 Concrete anti-patterns with code examples

Anti-pattern descriptions include specific code-level examples, not abstract categories.

| Bad (abstract) | Good (concrete) |
|-----------------|-----------------|
| "Poor separation of concerns" | "Domain class imports ORM: `from sqlalchemy import Column` in `Order` entity" |
| "High coupling" | "Module A imports Module B which imports Module A (circular dependency)" |
| "Leaky abstraction" | "`@Entity` annotations on domain classes — persistence details in the domain layer" |

### 5.4 Positive observations required

Every review MUST include a "What's Good" section. Reviews that only list problems are demoralising and less actionable. Positive architectural patterns give teams confidence about what to preserve and build on.

### 5.5 Hygiene gate is consequence-based

The Hygiene gate uses three consequence-severity tests (Irreversible, Total, Regulated), not domain-specific checklists. This ensures consistent escalation logic across all domains.

### 5.6 Severity is about structural impact

| Level | Definition | Decision |
|-------|-----------|----------|
| **HIGH** | Fundamental design flaw — systemic risk that will compound over time | Must fix before merge |
| **MEDIUM** | Design smell — principle violation with localised impact | May require follow-up ticket |
| **LOW** | Style improvement — minor suggestion, no structural risk | Nice to have |

Severity measures the **structural consequence** if the design ships as-is — how much harder will the system be to change, test, and operate. Not how hard the fix is.

### 5.7 Zoom levels scale to project size

Not every project operates at all zoom levels. The Architecture review adapts:
- **Small project / monolith**: Code + Service always apply. System + Landscape may return "no findings" — that's correct, not a gap.
- **Microservices**: All four levels should produce meaningful findings.
- **Library / SDK**: Code is primary, Service may partially apply.

Agents should not fabricate findings to fill a level. "No findings at this zoom level" is a valid and desirable output for projects where the level doesn't apply.

### 5.8 Design-time focus

Architecture reviews evaluate **design-time decisions**, not run-time behaviour. When a finding could be claimed by either Architecture or SRE, the distinction is:

| Concept | Architecture asks | SRE asks |
|---------|-------------------|----------|
| Circuit Breaker | "Is this the right pattern?" | "Is it configured and monitored?" |
| Coupling | "Is the dependency appropriate?" | "Does it cause cascading failure?" |
| Error handling | "Is the error model well-designed?" | "Can operators diagnose from errors?" |
| Deployability | "Is it independently deployable?" | "Can it be safely rolled out?" |

## 6. Orchestration Process

The `/review-arch` skill follows this process:

### Step 1: Scope identification

- File or directory argument: review that path
- Empty or ".": review recent changes (`git diff`) or prompt for scope
- PR number: fetch the diff
- Determine which zoom levels are relevant to the project size

### Step 2: Parallel dispatch

Spawn 4 subagents simultaneously:

| Agent | Model | Rationale |
|-------|-------|-----------|
| `arch-code` | sonnet | Nuanced judgement on SOLID compliance, DDD tactical correctness, and code quality assessment |
| `arch-service` | sonnet | Complex analysis of bounded context alignment, layering violations, and deployability |
| `arch-system` | sonnet | Subtle inter-service coupling analysis, stability pattern evaluation |
| `arch-landscape` | sonnet | Complex governance analysis, context map evaluation, ADR/spec traceability |

**Model selection rationale:** All four Architecture agents use sonnet because architectural review requires nuanced design judgement at every level. Unlike Security or SRE where some pillars have more binary criteria (present/absent), all architecture levels require interpreting code structure against design principles — a fundamentally interpretive task.

### Step 3: Synthesis

1. **Collect** findings from all 4 zoom levels
2. **Deduplicate** — when two agents flag the same `file:line`, merge into one finding:
   - Take the **highest severity**
   - Take the **most restrictive maturity level** (HYG > L1 > L2 > L3)
   - Combine recommendations from both agents
   - Credit both zoom levels in the Zoom Level column (e.g., "Code / Service")
3. **Aggregate maturity** — merge per-criterion assessments into one view:
   - All criteria met = `pass`
   - Mix of met and not met = `partial`
   - All criteria not met = `fail`
   - Previous level not passed = `locked`
4. **Prioritise** — HYG findings first, then by severity (HIGH > MEDIUM > LOW)

### Step 4: Output

Produce the maturity assessment report per the output format defined in `_base.md`.

## 7. Improvement Vectors

Known gaps that future work should address, in priority order:

| # | Gap | Impact | Direction |
|---|-----|--------|-----------|
| 1 | **No calibration examples in prompts** | Severity judgements are inconsistent across runs — the same God class might be HIGH in one review and MEDIUM in another | Add worked examples per severity per zoom level (see `calibration.md` in this spec) |
| 2 | **Zoom level overlap on coupling** | Code-level coupling and System-level coupling are different concerns but reviewers sometimes conflate them | Clarify boundary: Code owns intra-module coupling (class-to-class), System owns inter-service coupling (service-to-service). Document in `framework-map.md` |
| 3 | **L1 "sufficient" is undefined** | "Module boundaries are explicit with defined public interfaces" is subjective — what counts as explicit? | Define minimum thresholds (see `maturity-criteria.md`) |
| 4 | **Landscape level over-reports on small projects** | Landscape agent sometimes flags "missing ADRs" on single-file scripts | Improve scaling guidance: agent should assess project size before reporting L2/L3 governance criteria |
| 5 | **No technology-specific supplements** | Checklists can't recognise framework-specific patterns (e.g., Django vs Spring DI conventions) | Future: add optional supplements for Python, Java, Go, Node, .NET |
| 6 | **DDD tactical assessment is shallow** | The code-level DDD checklist identifies Value Objects and Aggregates but doesn't evaluate their correctness deeply | Future: add concrete guidance on aggregate sizing, eventual consistency boundaries, event design |
| 7 | **No design-decision impact analysis** | Reviews identify what's wrong but don't estimate the cost of the architectural debt | Future: add optional "change cost" qualifier (trivial / moderate / significant refactor) |
| 8 | **No cross-review learning** | Each review is stateless | Future: use `.code-review/` history to track architectural maturity progression |

## 8. Constraints

Things the Architecture domain deliberately does NOT do:

- **No auto-fix.** The review is read-only. Agents have Read, Grep, Glob tools only — no Bash, no Write, no Edit.
- **No cross-domain findings.** Architecture does not flag SRE, security, or data issues. Those belong to their respective domains.
- **No numeric scores.** Status is pass/partial/fail/locked. No percentages, no weighted scores, no "architecture health index".
- **No prescribing specific tools.** Never recommend a specific library, framework, or vendor. Describe the outcome, let the team choose the implementation.
- **No prescribing specific patterns by name.** Do not require "DDD" or "Clean Architecture" or "Hexagonal Architecture". Describe the structural property the code should exhibit. The team may achieve it through any approach.
- **No fabricating findings.** If a zoom level doesn't apply to the project (e.g., Landscape for a single-service monolith), return "no findings" — do not invent concerns to fill the report.
