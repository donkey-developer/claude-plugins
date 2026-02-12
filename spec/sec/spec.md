# Security Domain Specification

> Canonical reference for building, improving, and maintaining the Security review domain within the donkey-dev Claude Code plugin.

## 1. Purpose

The Security review domain evaluates code changes through the lens of threat modelling. It answers one question: **"If an attacker targets this, what can they achieve?"**

The domain produces a structured maturity assessment that tells engineering leaders:
- What an attacker can exploit today (Hygiene failures)
- What security foundations are missing (L1 gaps)
- What hardened security posture looks like for this codebase (L2 criteria)
- What security excellence would require (L3 aspirations)

## 2. Audience

| Who | Uses the spec for |
|-----|-------------------|
| **Autonomous coding agents** | Building/modifying prompt files, agent definitions, skill orchestrators |
| **Human prompt engineers** | Reviewing agent output, calibrating severity, refining checklists |
| **Plugin consumers** | Understanding what the Security review evaluates and why |

## 3. Conceptual Architecture

The Security domain is built from three interlocking layers:

```
+----------------------------------------------+
|         STRIDE Framework (Structure)          |   Organises WHAT to review
|  Spoofing . Tampering . Repudiation .         |
|  Info Disclosure . DoS . Elevation            |
+----------------------------------------------+
|   STRIDE (Threat)  <-->  Properties (Defence) |   Analytical LENSES
|   "What can an         "What protects          |
|    attacker do?"        against it?"           |
+----------------------------------------------+
|         Maturity Model (Judgement)             |   Calibrates SEVERITY
|    Hygiene --> L1 --> L2 --> L3                |   and PRIORITY
+----------------------------------------------+
```

- **STRIDE** provides the structural decomposition (6 threat categories distributed across 4 pillars, 4 subagents).
- **STRIDE Threats** and **Security Properties** provide the analytical duality — threats are the "offensive" lens, security properties are the "defensive" lens.
- **DREAD-lite** provides the severity scoring framework for individual findings.
- **The Maturity Model** provides the judgement framework for prioritising findings.

These layers are defined in detail in the companion files:
- `glossary.md` — canonical definitions
- `framework-map.md` — how STRIDE threats, security properties, and pillars relate to each other
- `maturity-criteria.md` — detailed criteria with "sufficient" thresholds
- `calibration.md` — worked examples showing severity judgement
- `anti-patterns.md` — concrete code smells per pillar
- `references.md` — source attribution

## 4. File Layout

The Security domain manifests as these files within the plugin:

```
donkey-dev/
  agents/
    security-authn-authz.md       # Subagent: Spoofing + Elevation of Privilege
    security-data-protection.md   # Subagent: Information Disclosure + Tampering
    security-input-validation.md  # Subagent: Tampering (Injection)
    security-audit-resilience.md  # Subagent: Repudiation + Denial of Service
  prompts/security/
    _base.md                      # Shared context: STRIDE, DREAD-lite, maturity model, output format
    authn-authz.md                # Authentication & Authorization pillar checklist
    data-protection.md            # Data Protection pillar checklist
    input-validation.md           # Input Validation pillar checklist
    audit-resilience.md           # Audit & Resilience pillar checklist
  skills/
    review-security/SKILL.md      # Orchestrator: scope, parallel dispatch, synthesis, output
```

### Composition rules

1. **Each agent file is self-contained.** It embeds the full content of `_base.md` + its pillar prompt. Agents do not reference external files at runtime — all context must be inlined.
2. **Prompts are the source of truth.** The `prompts/security/` directory contains the human-readable, LLM-agnostic checklists. Agent files are compiled from these.
3. **The skill orchestrator dispatches and synthesises.** It does not contain review logic — that lives in the agents.

### When modifying files

| Change type | Files to update |
|-------------|-----------------|
| Add/change a checklist item | `prompts/security/<pillar>.md` then recompile the corresponding `agents/security-<pillar>.md` |
| Change shared context (severity, maturity, output format) | `prompts/security/_base.md` then recompile ALL 4 agent files |
| Change orchestration logic | `skills/review-security/SKILL.md` only |
| Add a new pillar | New prompt file, new agent file, update SKILL.md to spawn 5th agent |

## 5. Design Principles

These principles govern all prompt changes in the Security domain. They align with the cross-domain principles established in PRs #18 and #19 and must be preserved.

### 5.1 Outcomes over techniques

Maturity criteria describe **observable outcomes**, not named tools, libraries, or standards.

| Bad (technique) | Good (outcome) |
|-----------------|----------------|
| "Uses SAST/DAST" | "Security checks run automatically in the build pipeline" |
| "Implements OAuth 2.0" | "Authentication and authorisation are applied consistently on all protected paths" |
| "Has a WAF" | "Input validation on all entry points" |
| "Uses HashiCorp Vault" | "Secrets are loaded from environment or external store, not source" |

**Rationale (PR #19):** Technique names create false negatives — a team using AWS Secrets Manager satisfies "secrets from external store" but wouldn't match "uses HashiCorp Vault". Outcomes are technology-neutral and verifiable from code.

### 5.2 Questions over imperatives

Checklists use questions to prompt investigation, not imperatives to demand compliance.

| Bad (imperative) | Good (question) |
|-------------------|-----------------|
| "Enforce input validation" | "Is external input validated before processing?" |
| "Use parameterized queries" | "Are parameterized queries or prepared statements used?" |

**Rationale:** Questions guide the reviewer to investigate the code and form a judgement. Imperatives produce binary "present/absent" assessments that miss nuance.

### 5.3 Concrete anti-patterns with exploit scenarios

Anti-pattern descriptions include specific code-level examples AND how an attacker would exploit them.

| Bad (abstract) | Good (concrete) |
|-----------------|-----------------|
| "Insecure authentication" | "`jwt.decode(token, options={\"verify_signature\": False})` — attacker crafts a token with any claims and it's accepted" |
| "Injection vulnerability" | "`f\"SELECT * FROM users WHERE id = {user_id}\"` — attacker sends `1 OR 1=1` to dump all records" |

### 5.4 Exploit path required for every finding

Every security finding must include an exploit scenario. A vulnerability without an exploit path is a theoretical concern, not a finding. This is the core distinction between security review and security audit — the review focuses on **exploitable** weaknesses.

### 5.5 Positive observations required

Every review MUST include a "What's Good" section. Reviews that only list problems are demoralising and less actionable. Positive security patterns give teams confidence about what to preserve and build on.

### 5.6 Confidence thresholds reduce noise

Security reviews are particularly prone to false positives. The confidence threshold system exists to maintain signal quality:
- **HIGH (>80%)**: Clear exploit path visible in code — MUST REPORT
- **MEDIUM (50-80%)**: Requires specific conditions — REPORT with caveat
- **LOW (<50%)**: Theoretical — DO NOT REPORT

This is a deliberate trade-off: prefer fewer, higher-confidence findings over comprehensive-but-noisy reports. Teams stop reading security reviews that cry wolf.

### 5.7 Hygiene gate is consequence-based

The Hygiene gate uses three consequence-severity tests (Irreversible, Total, Regulated), not domain-specific checklists. This ensures consistent escalation logic across all domains.

### 5.8 Severity is about exploitation impact

| Level | Definition | Decision |
|-------|-----------|----------|
| **HIGH** | Direct exploitation leads to RCE, data breach, or auth bypass | Must fix before merge |
| **MEDIUM** | Requires specific conditions, significant impact if exploited | May require follow-up ticket |
| **LOW** | Limited impact, defence-in-depth improvement | Nice to have |

Severity measures **exploitation consequence**, not how hard the fix is.

### 5.9 Explicit exclusions reduce noise

The Security domain maintains a deliberate exclusion list (see `glossary.md`). These are categories that create noise without value in a code review context because they are either handled by dedicated tooling (dependency scanning, secret scanning) or are theoretical without a demonstrated exploit path.

## 6. Orchestration Process

The `/review-security` skill follows this process:

### Step 1: Scope identification

- File or directory argument: review that path
- Empty or ".": review recent changes (`git diff`) or prompt for scope
- PR number: fetch the diff

### Step 2: Parallel dispatch

Spawn 4 subagents simultaneously:

| Agent | Model | Rationale |
|-------|-------|-----------|
| `security-authn-authz` | sonnet | Nuanced judgement on auth bypass patterns and privilege escalation |
| `security-data-protection` | sonnet | Complex analysis of crypto usage, secrets exposure, data classification |
| `security-input-validation` | sonnet | Subtle injection pattern recognition across frameworks |
| `security-audit-resilience` | haiku | More binary checklist (rate limits exist or not, audit logs present or not) |

**Model selection rationale:** The authn-authz, data-protection, and input-validation pillars require nuanced pattern recognition — detecting subtle auth bypasses, evaluating cryptographic choices, and recognising framework-specific injection patterns. The audit-resilience pillar is more binary (rate limiting exists or doesn't, audit logging present or not) and can use a faster model.

### Step 3: Synthesis

1. **Collect** findings from all 4 pillars
2. **Apply confidence filter** — remove findings below 50% confidence
3. **Deduplicate** — when two agents flag the same `file:line`, merge into one finding:
   - Take the **highest severity**
   - Take the **most restrictive maturity level** (HYG > L1 > L2 > L3)
   - Combine recommendations from both agents
   - Credit both pillars in the STRIDE column (e.g., "T / I" for Tampering + Information Disclosure)
4. **Aggregate maturity** — merge per-criterion assessments into one view:
   - All criteria met = `pass`
   - Mix of met and not met = `partial`
   - All criteria not met = `fail`
   - Previous level not passed = `locked`
5. **Prioritise** — HYG findings first, then by severity (HIGH > MEDIUM > LOW)

### Step 4: Output

Produce the maturity assessment report per the output format defined in `_base.md`.

## 7. Improvement Vectors

Known gaps that future work should address, in priority order:

| # | Gap | Impact | Direction |
|---|-----|--------|-----------|
| 1 | **No calibration examples in prompts** | Severity judgements are inconsistent across runs | Add worked examples per severity per pillar (see `calibration.md` in this spec) |
| 2 | **Pillar overlap on Tampering** | Input-validation and data-protection both cover Tampering, risking duplicates | Clarify boundary: input-validation owns injection (untrusted input alters behaviour), data-protection owns integrity (data modified at rest or in transit). Document in `framework-map.md` |
| 3 | **No technology-specific supplements** | Checklists can't recognise framework-specific patterns beyond the basic table | Future: add optional supplements for Python, Java, Go, Node, .NET, React, Django, Rails |
| 4 | **DREAD-lite is applied inconsistently** | Some findings use DREAD factors explicitly, others just state HIGH/MEDIUM/LOW | Future: enforce that each finding includes Damage/Exploitability/Affected Scope assessment |
| 5 | **Audit-resilience model mismatch** | Audit (Repudiation) and DoS (Denial of Service) are fundamentally different concern types paired in one agent | Evaluate whether splitting into two agents would improve focus. Counter-argument: both are "operational security" concerns and haiku handles the lighter workload |
| 6 | **No threat model composition** | Reviews are stateless — no way to build a cumulative threat model across multiple reviews | Future: use `.code-review/` history to build up a threat model over time |
| 7 | **Supply chain security not covered** | No pillar addresses dependency supply chain risks | Currently excluded (handled by dependency scanning tools). Evaluate if actionable code-level patterns exist |
| 8 | **No cross-review learning** | Each review starts from scratch | Future: use `.code-review/` history to track security posture progression |

## 8. Constraints

Things the Security domain deliberately does NOT do:

- **No auto-fix.** The review is read-only. Agents have Read, Grep, Glob tools only — no Bash, no Write, no Edit.
- **No cross-domain findings.** Security does not flag architecture, SRE, or data issues. Those belong to their respective domains.
- **No numeric scores.** Status is pass/partial/fail/locked. No percentages, no weighted DREAD scores, no CVSS.
- **No prescribing specific tools.** Never recommend a specific library, vendor, or standard. Describe the outcome, let the team choose the implementation.
- **No dependency scanning.** Outdated dependencies with known CVEs are handled by dedicated tools (Dependabot, Snyk, etc.). The Security review focuses on code-level vulnerabilities.
- **No secret scanning.** Committed secrets are handled by dedicated tools (git-secrets, TruffleHog, etc.). The Security review flags hardcoded secrets visible in the code being reviewed, but does not scan git history.
- **No penetration testing.** The review analyses code statically. It does not execute code, send requests, or probe running services.
