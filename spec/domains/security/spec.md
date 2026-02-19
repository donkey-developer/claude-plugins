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

This domain inherits the shared audience definitions (see `../../review-standards/review-framework.md`).

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

This domain inherits the shared plugin file layout (see `../../review-standards/review-framework.md`). Domain-specific files:

| Location | File | Purpose |
|----------|------|---------|
| `agents/` | `security-authn-authz.md` | Subagent: Spoofing + Elevation of Privilege |
| `agents/` | `security-data-protection.md` | Subagent: Information Disclosure + Tampering |
| `agents/` | `security-input-validation.md` | Subagent: Tampering (Injection) |
| `agents/` | `security-audit-resilience.md` | Subagent: Repudiation + Denial of Service |
| `prompts/security/` | `_base.md` | Shared context: STRIDE, DREAD-lite, maturity model, output format |
| `prompts/security/` | `authn-authz.md` | Authentication & Authorization pillar checklist |
| `prompts/security/` | `data-protection.md` | Data Protection pillar checklist |
| `prompts/security/` | `input-validation.md` | Input Validation pillar checklist |
| `prompts/security/` | `audit-resilience.md` | Audit & Resilience pillar checklist |
| `skills/` | `security/SKILL.md` | Orchestrator: scope, parallel dispatch, synthesis, output |

## 5. Design Principles

This domain inherits the shared design principles (see `../../review-standards/design-principles.md`) and adds domain-specific principles and examples below.

### 5.1 Outcomes over techniques (domain examples)

| Bad (technique) | Good (outcome) |
|-----------------|----------------|
| "Uses SAST/DAST" | "Security checks run automatically in the build pipeline" |
| "Implements OAuth 2.0" | "Authentication and authorisation are applied consistently on all protected paths" |
| "Has a WAF" | "Input validation on all entry points" |
| "Uses HashiCorp Vault" | "Secrets are loaded from environment or external store, not source" |

### 5.2 Questions over imperatives (domain examples)

| Bad (imperative) | Good (question) |
|-------------------|-----------------|
| "Enforce input validation" | "Is external input validated before processing?" |
| "Use parameterized queries" | "Are parameterized queries or prepared statements used?" |

### 5.3 Concrete anti-patterns with exploit scenarios (domain examples)

| Bad (abstract) | Good (concrete) |
|-----------------|-----------------|
| "Insecure authentication" | "`jwt.decode(token, options={\"verify_signature\": False})` — attacker crafts a token with any claims and it's accepted" |
| "Injection vulnerability" | "`f\"SELECT * FROM users WHERE id = {user_id}\"` — attacker sends `1 OR 1=1` to dump all records" |

### 5.4 Exploit path required for every finding

Every security finding that clears the confidence filter (≥50%) must include an exploit path — no exceptions, regardless of severity.
A vulnerability without an exploit path is a theoretical concern, not a finding.
This is the core distinction between security review and security audit — the review focuses on **exploitable** weaknesses.

Per-severity expectations:

- **HIGH:** Full exploit scenario describing attacker steps, preconditions, and impact.
- **MEDIUM:** Exploit path may be brief (one or two sentences) but must describe a concrete attack vector.
- **LOW:** Exploit path may be brief (one or two sentences) but must describe how an attacker could realistically leverage the weakness.
- **No exploit path = not a finding.** If an exploit path cannot be described at ≥50% confidence, the finding does not clear the confidence filter and must be dropped.

**Rationale (Review Output Conformance, #56):**
If the reviewing agent cannot articulate how an attacker would exploit a weakness, the developer reading the report certainly will not understand the risk.
The per-severity scaling is a pragmatic compromise: LOW findings do not need a multi-step scenario, but they do need a concrete attack vector to be distinguishable from noise.
Making exploit paths optional for LOW severity was considered and rejected because LOWs without exploit paths are indistinguishable from false positives.
This reinforces the same philosophy as the confidence threshold — prefer fewer, actionable findings over comprehensive but vague reports.

### 5.5 Confidence thresholds reduce noise

Security reviews are particularly prone to false positives. The confidence threshold system exists to maintain signal quality:
- **HIGH (>80%)**: Clear exploit path visible in code — MUST REPORT
- **MEDIUM (50-80%)**: Requires specific conditions — REPORT with caveat
- **LOW (<50%)**: Theoretical — DO NOT REPORT

This is a deliberate trade-off: prefer fewer, higher-confidence findings over comprehensive-but-noisy reports. Teams stop reading security reviews that cry wolf.

### 5.6 Severity is about exploitation impact

| Level | Definition | Decision |
|-------|-----------|----------|
| **HIGH** | Direct exploitation leads to RCE, data breach, or auth bypass | Must fix before merge |
| **MEDIUM** | Requires specific conditions, significant impact if exploited | May require follow-up ticket |
| **LOW** | Limited impact, defence-in-depth improvement | Nice to have |

Severity measures **exploitation consequence**, not how hard the fix is.

### 5.7 Explicit exclusions reduce noise

The Security domain maintains a deliberate exclusion list (see `glossary.md`). These are categories that create noise without value in a code review context because they are either handled by dedicated tooling (dependency scanning, secret scanning) or are theoretical without a demonstrated exploit path.

### 5.8 Fix directions describe outcomes, not tools

Fix-direction text must not name specific functions, libraries, or numeric thresholds.
Qualifying with `e.g.` does not satisfy this constraint — the named tool still anchors the reader on a single solution.
Describe the required security outcome; let the implementing team choose the mechanism.

| Bad (tool-phrased) | Good (outcome-phrased) |
|---------------------|------------------------|
| "Replace `===` with `crypto.timingSafeEqual(Buffer.from(providedKey), Buffer.from(expectedKey))`" | "Use a constant-time byte comparison to prevent timing side-channels" |
| "Apply per-IP rate limiting (e.g., `express-rate-limit`). Minimum: 5 failed auth attempts per 15 minutes triggers temporary lockout" | "Apply per-IP rate limiting with temporary lockout on repeated authentication failures" |

**Rationale (Review Output Conformance, #54):**
Named tools anchor the reader on a single solution and implicitly endorse a vendor.
Testing showed that even qualifying with "e.g." does not prevent anchoring — agents and readers still treat the named tool as the recommendation.
Outcome-phrased recommendations let teams choose tools that fit their existing stack and constraints.

## 6. Orchestration Process

The `/donkey-review:security` skill follows the shared orchestration pattern (see `../../review-standards/orchestration.md`) with these domain-specific details:

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

Follows the shared synthesis algorithm (see `../../review-standards/orchestration.md`) with one domain-specific addition:

1. **Collect** findings from all 4 pillars
2. **Apply confidence filter** — remove findings below 50% confidence
3. Continue with shared deduplication, aggregation, and prioritisation

## 7. Improvement Vectors

Known gaps that future work should address, in priority order:

| # | Gap | Impact | Direction |
|---|-----|--------|-----------|
| 1 | **No calibration examples in prompts** | Severity judgements are inconsistent across runs | Add worked examples per severity per pillar (see `calibration.md` in this spec) |
| 2 | **Pillar overlap on Tampering** | Input-validation and data-protection both cover Tampering, risking duplicates | Clarify boundary: input-validation owns injection (untrusted input alters behaviour), data-protection owns integrity (data modified at rest or in transit). Document in `framework-map.md` |
| 3 | **No technology-specific supplements** | Checklists can't recognise framework-specific patterns beyond the basic table | Future: add optional supplements for Python, Java, Go, Node, .NET, React, Django, Rails |
| 4 | **DREAD-lite is applied inconsistently** | Some findings use DREAD factors explicitly, others just state HIGH/MEDIUM/LOW | Future: enforce that each finding includes Damage/Exploitability/Affected Scope assessment |
| 5 | **Audit-resilience model mismatch** | Audit (Repudiation) and DoS (Denial of Service) are fundamentally different concern types paired in one agent | Evaluate whether splitting into two agents would improve focus. Counter-argument: both are "operational security" concerns and haiku handles the lighter workload |
| 6 | **No threat model composition** | Reviews are stateless — no way to build a cumulative threat model across multiple reviews | Future: use `.donkey-review/` history to build up a threat model over time |
| 7 | **Supply chain security not covered** | No pillar addresses dependency supply chain risks | Currently excluded (handled by dependency scanning tools). Evaluate if actionable code-level patterns exist |
| 8 | **No cross-review learning** | Each review starts from scratch | Future: use `.donkey-review/` history to track security posture progression |

## 8. Constraints

This domain inherits the universal constraints (see `../../review-standards/review-framework.md`) and adds:

- **No dependency scanning.** Outdated dependencies with known CVEs are handled by dedicated tools (Dependabot, Snyk, etc.). The Security review focuses on code-level vulnerabilities.
- **No secret scanning.** Committed secrets are handled by dedicated tools (git-secrets, TruffleHog, etc.). The Security review flags hardcoded secrets visible in the code being reviewed, but does not scan git history.
- **No penetration testing.** The review analyses code statically. It does not execute code, send requests, or probe running services.
