# SRE Domain Specification

> Canonical reference for building, improving, and maintaining the SRE review domain within the donkey-dev Claude Code plugin.

## 1. Purpose

The SRE review domain evaluates code changes through the lens of operational reliability. It answers one question: **"If we ship this, what will 3am look like?"**

The domain produces a structured maturity assessment that tells engineering leaders:
- What will break in production (Hygiene failures)
- What foundations are missing (L1 gaps)
- What operational maturity looks like for this codebase (L2 criteria)
- What excellence would require (L3 aspirations)

## 2. Audience

| Who | Uses the spec for |
|-----|-------------------|
| **Autonomous coding agents** | Building/modifying prompt files, agent definitions, skill orchestrators |
| **Human prompt engineers** | Reviewing agent output, calibrating severity, refining checklists |
| **Plugin consumers** | Understanding what the SRE review evaluates and why |

## 3. Conceptual Architecture

The SRE domain is built from three interlocking layers:

```
+----------------------------------------------+
|          ROAD Framework (Structure)          |   Organises WHAT to review
|  Response . Observability .                  |
|  Availability . Delivery                     |
+----------------------------------------------+
|    SEEMS (Attack)  <-->  FaCTOR (Defence)    |   Analytical LENSES
|    "How will this      "What protects        |
|     fail?"              against it?"         |
+----------------------------------------------+
|         Maturity Model (Judgement)            |   Calibrates SEVERITY
|    Hygiene --> L1 --> L2 --> L3               |   and PRIORITY
+----------------------------------------------+
```

- **ROAD** provides the structural decomposition (4 pillars, 4 subagents).
- **SEEMS** and **FaCTOR** provide the analytical lenses applied within each pillar.
- **The Maturity Model** provides the judgement framework for prioritising findings.

These layers are defined in detail in the companion files:
- `glossary.md` — canonical definitions
- `framework-map.md` — how SEEMS, FaCTOR, and ROAD relate to each other
- `maturity-criteria.md` — detailed criteria with "sufficient" thresholds
- `calibration.md` — worked examples showing severity judgement
- `anti-patterns.md` — concrete code smells per pillar
- `references.md` — source attribution

## 4. File Layout

The SRE domain manifests as these files within the plugin:

```
donkey-dev/
  agents/
    sre-response.md          # Subagent: incident response readiness
    sre-observability.md     # Subagent: logging, metrics, tracing
    sre-availability.md      # Subagent: SLOs, resilience, load management
    sre-delivery.md          # Subagent: deployment safety, rollback
  prompts/sre/
    _base.md                 # Shared context: SEEMS, FaCTOR, maturity model, output format
    response.md              # Response pillar checklist
    observability.md         # Observability pillar checklist
    availability.md          # Availability pillar checklist
    delivery.md              # Delivery pillar checklist
  skills/
    review-sre/SKILL.md      # Orchestrator: scope, parallel dispatch, synthesis, output
```

### Composition rules

1. **Each agent file is self-contained.** It embeds the full content of `_base.md` + its pillar prompt. Agents do not reference external files at runtime — all context must be inlined.
2. **Prompts are the source of truth.** The `prompts/sre/` directory contains the human-readable, LLM-agnostic checklists. Agent files are compiled from these.
3. **The skill orchestrator dispatches and synthesises.** It does not contain review logic — that lives in the agents.

### When modifying files

| Change type | Files to update |
|-------------|-----------------|
| Add/change a checklist item | `prompts/sre/<pillar>.md` then recompile the corresponding `agents/sre-<pillar>.md` |
| Change shared context (severity, maturity, output format) | `prompts/sre/_base.md` then recompile ALL 4 agent files |
| Change orchestration logic | `skills/review-sre/SKILL.md` only |
| Add a new ROAD pillar | New prompt file, new agent file, update SKILL.md to spawn 5th agent |

## 5. Design Principles

These principles govern all prompt changes in the SRE domain. They emerged from the project's evolution (PRs #3, #17, #18, #19) and must be preserved.

### 5.1 Outcomes over techniques

Maturity criteria describe **observable outcomes**, not named techniques or libraries.

| Bad (technique) | Good (outcome) |
|-----------------|----------------|
| "Circuit breakers exist" | "External dependencies have failure isolation" |
| "Uses structured logging" | "Logging is structured with request correlation" |
| "Has Prometheus metrics" | "SLI-relevant metrics are exposed and measurable" |
| "Implements SEEMS/FaCTOR" | "Failure modes are identified and resilience properties verified" |

**Rationale (PR #19):** Technique names create false negatives — a team using Polly for retries with backoff satisfies the outcome but wouldn't match "uses Resilience4j". Outcomes are technology-neutral and verifiable from code.

### 5.2 Questions over imperatives

Checklists use questions to prompt investigation, not imperatives to demand compliance.

| Bad (imperative) | Good (question) |
|-------------------|-----------------|
| "Ensure requests are traceable" | "Can you trace a request through the system?" |
| "Add timeouts to all calls" | "Do all external calls have timeouts? Are they appropriate?" |

**Rationale:** Questions guide the reviewer to investigate the code and form a judgement. Imperatives produce binary "present/absent" assessments that miss nuance.

### 5.3 Concrete anti-patterns

Anti-pattern descriptions include specific code-level examples, not abstract categories.

| Bad (abstract) | Good (concrete) |
|-----------------|-----------------|
| "Poor error handling" | "Generic error messages: 'An error occurred' / 'Something went wrong'" |
| "Inadequate logging" | "`console.log` / `print` statements instead of structured logging" |

### 5.4 Positive observations required

Every review MUST include a "What's Good" section. Reviews that only list problems are demoralising and less actionable. Positive patterns give teams confidence about what to preserve.

### 5.5 Hygiene gate is consequence-based

The Hygiene gate uses three consequence-severity tests (Irreversible, Total, Regulated), not domain-specific checklists. This ensures consistent escalation logic across all domains.

### 5.6 Severity is about production impact

| Level | Definition | Decision |
|-------|-----------|----------|
| **HIGH** | Could cause outage, data loss, or significant degradation | Must fix before merge |
| **MEDIUM** | Operational risk that should be addressed | May require follow-up ticket |
| **LOW** | Minor improvement opportunity | Nice to have |

Severity is about the **production consequence** if the code ships as-is, not about how hard the fix is.

## 6. Orchestration Process

The `/review-sre` skill follows this process:

### Step 1: Scope identification

- File or directory argument: review that path
- Empty or ".": review recent changes (`git diff`) or prompt for scope
- PR number: fetch the diff

### Step 2: Parallel dispatch

Spawn 4 subagents simultaneously:

| Agent | Model | Rationale |
|-------|-------|-----------|
| `sre-response` | sonnet | Nuanced judgement on error message quality and runbook readiness |
| `sre-observability` | sonnet | Complex analysis of logging/metrics/tracing completeness |
| `sre-availability` | sonnet | Subtle resilience pattern analysis |
| `sre-delivery` | haiku | More binary checklist (backward-compatible or not, reversible or not) |

### Step 3: Synthesis

1. **Collect** findings from all 4 pillars
2. **Deduplicate** — when two agents flag the same `file:line`, merge into one finding:
   - Take the **highest severity**
   - Take the **most restrictive maturity level** (HYG > L1 > L2 > L3)
   - Combine recommendations from both agents
   - Credit both pillars in the Category column (e.g., "Availability / Response")
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
| 1 | **SEEMS-FaCTOR duality unlinked** | Reviewers treat them as separate checklists | Add explicit mapping: "this SEEMS failure is mitigated by this FaCTOR property" (see `framework-map.md`) |
| 2 | **No calibration examples** | Severity judgements are inconsistent across runs | Add worked examples per severity per pillar (see `calibration.md`) |
| 3 | **L1 "sufficient" is undefined** | "Errors propagate with context sufficient for diagnosis" is subjective | Define minimum thresholds (see `maturity-criteria.md`) |
| 4 | **Deduplication rules were implicit** | Synthesis step produced inconsistent merges | Now defined in Section 6 above |
| 5 | **No technology-specific supplements** | Checklists can't recognise framework-specific patterns | Future: add optional supplements for Python, Java, Go, Node, .NET |
| 6 | **SLO treatment is shallow** | SLOs mentioned but not operationalised | Future: add concrete guidance on SLO-aligned code patterns |
| 7 | **No confidence signal** | Agents can't express uncertainty | Future: add optional confidence qualifier (confirmed / likely / possible) |
| 8 | **No cross-review learning** | Each review is stateless | Future: use `.code-review/` history to track maturity progression |

## 8. Constraints

Things the SRE domain deliberately does NOT do:

- **No auto-fix.** The review is read-only. Agents have Read, Grep, Glob tools only — no Bash, no Write, no Edit.
- **No cross-domain findings.** SRE does not flag architecture, security, or data issues. Those belong to their respective domains.
- **No numeric scores.** Status is pass/partial/fail/locked. No percentages, no weighted scores.
- **No prescribing specific tools.** Never recommend a specific library or vendor. Describe the outcome, let the team choose the implementation.
