# Glossary — Security Domain

> Canonical definitions for all terms, frameworks, and acronyms used in the Security review domain. When writing or modifying prompts, use these definitions exactly.

## Frameworks

### STRIDE

**Spoofing, Tampering, Repudiation, Information Disclosure, Denial of Service, Elevation of Privilege.** The structural framework that organises the Security review into threat categories, distributed across 4 pillars with dedicated subagents.

Origin: Microsoft (Loren Kohnfelder and Praerit Garg, 1999). Widely adopted as a systematic threat modelling approach.

| Category | Security Property | What to look for |
|----------|------------------|-----------------|
| **S**poofing | Authenticity | Can an attacker pretend to be someone else? Authentication bypass, credential theft, session hijacking. |
| **T**ampering | Integrity | Can an attacker modify data they shouldn't? Input manipulation, data corruption, unauthorised writes. |
| **R**epudiation | Non-repudiability | Can an attacker deny their actions? Missing audit logs, unsigned transactions, no accountability trail. |
| **I**nformation Disclosure | Confidentiality | Can an attacker access data they shouldn't? Data leaks, excessive logging, exposed secrets. |
| **D**enial of Service | Availability | Can an attacker disrupt the service? Resource exhaustion, algorithmic complexity, missing rate limits. |
| **E**levation of Privilege | Authorization | Can an attacker gain unauthorised access? Privilege escalation, broken access control, insecure defaults. |

### DREAD-lite

A simplified severity scoring framework derived from Microsoft's original DREAD model. Uses three of the five original factors.

| Factor | Question | HIGH | MEDIUM | LOW |
|--------|----------|------|--------|-----|
| **D**amage | What's the worst case? | Data breach, RCE, full compromise | Limited data access, partial control | Minor information leak |
| **E**xploitability | How easy to exploit? | Trivial, no auth required | Requires specific conditions | Complex, requires insider access |
| **A**ffected scope | How many users/systems? | All users, critical systems | Subset of users, non-critical | Single user, isolated system |

**Usage:** DREAD-lite factors inform severity (HIGH/MEDIUM/LOW) but are not scored numerically. Reviewers assess each factor qualitatively and use the combination to determine overall severity.

### STRIDE–Property Duality

Every STRIDE threat has a corresponding security property that mitigates it. See `framework-map.md` for the complete mapping.

| STRIDE threat | Defensive property |
|---------------|-------------------|
| Spoofing | Authenticity |
| Tampering | Integrity |
| Repudiation | Non-repudiability |
| Information Disclosure | Confidentiality |
| Denial of Service | Availability |
| Elevation of Privilege | Authorization |

## Pillars

| Pillar | STRIDE categories | One-line mandate |
|--------|------------------|-----------------|
| **authn-authz** | Spoofing + Elevation of Privilege | Can attackers impersonate users or gain access they shouldn't have? |
| **data-protection** | Information Disclosure + Tampering (integrity) | Can attackers access data they shouldn't see or modify data without detection? |
| **input-validation** | Tampering (injection) | Can malicious input alter the intended behaviour of the system? |
| **audit-resilience** | Repudiation + Denial of Service | Can users deny their actions? Can attackers disrupt service availability? |

## Confidence Thresholds

| Confidence | Threshold | Action | Examples |
|------------|-----------|--------|----------|
| **HIGH** | >80% | MUST REPORT | Clear SQL injection, hardcoded secrets, missing auth check on sensitive endpoint |
| **MEDIUM** | 50-80% | REPORT with caveat | Potential race condition, possible bypass under specific conditions |
| **LOW** | <50% | DO NOT REPORT | Theoretical attacks, defence-in-depth suggestions |

**Design rationale:** Security reviews are especially prone to false positives. Reporting low-confidence findings erodes trust in the review process. Teams stop reading security reviews that cry wolf.

## Exclusions

Categories deliberately excluded from security review findings:

| Excluded category | Reason | Handled by |
|-------------------|--------|------------|
| Test file vulnerabilities | Test code is not production code | N/A |
| Documentation security issues | Docs describe, not implement | N/A |
| Theoretical timing attacks | Without proven exploit path, these are noise | Dedicated security testing |
| Missing hardening (defence-in-depth) | Absence of extra protection is not a vulnerability | Security maturity assessments |
| Secrets in git history | Requires history scanning, not code review | git-secrets, TruffleHog, GitHub secret scanning |
| Log spoofing | Low impact in most contexts | Operational monitoring |
| Memory safety in memory-safe languages | Rust, Go, etc. handle this at the language level | N/A |
| Outdated dependencies | Version-based vulnerability matching | Dependabot, Snyk, Renovate |
| Missing rate limiting (unless trivially exploitable) | Operational concern unless directly exploitable | SRE domain |
| Resource leaks | Memory/connection leaks are operational, not security | SRE domain |

## Maturity Model

### Hygiene Gate

A promotion gate that overrides maturity levels. Any finding at any level is promoted to `HYG` if it passes any of these three consequence-severity tests:

| Test | Question | Security examples |
|------|----------|-------------------|
| **Irreversible** | If this goes wrong, can the damage be undone? | User input concatenated into SQL or OS commands (data breach or RCE). API keys committed in source code (once pushed, compromised permanently). Authentication check missing on a destructive endpoint (data deleted). |
| **Total** | Can this take down the entire service or cascade beyond its boundary? | Unbounded query with no pagination on a public endpoint (DoS). Missing rate limiting on authentication endpoint enabling resource exhaustion. |
| **Regulated** | Does this violate a legal or compliance obligation? | PII logged without masking. Health data exposed in API responses. Payment card data stored without encryption. |

Any "yes" to any test = `HYG`. The Hygiene flag trumps all maturity levels.

### Maturity Levels

Levels are cumulative. Each requires the previous. See `maturity-criteria.md` for detailed criteria with thresholds.

| Level | Name | One-line description |
|-------|------|---------------------|
| **L1** | Foundations | The basics are in place. The system has authentication, validates input, and manages secrets. |
| **L2** | Hardening | Security-hardened practices. The system has audit trails, rate limits, and least privilege. |
| **L3** | Excellence | Best-in-class. Security is automated, encryption is configurable, dependencies are scanned. |

### Severity Levels

| Level | Exploitation impact | Merge decision |
|-------|---------------------|----------------|
| **HIGH** | Direct exploitation leads to RCE, data breach, or auth bypass | Must fix before merge |
| **MEDIUM** | Requires conditions, significant impact if exploited | May require follow-up ticket |
| **LOW** | Limited impact, defence-in-depth improvement | Nice to have |

Severity measures **exploitation consequence**, not implementation difficulty.

### Status Indicators

Used in maturity assessment tables:

| Indicator | Meaning |
|-----------|---------|
| `pass` | All criteria at this level are met |
| `partial` | Some criteria met, some not |
| `fail` | No criteria met, or critical criteria missing |
| `locked` | Previous level not achieved; this level cannot be assessed |

## Orchestration Terms

| Term | Definition |
|------|-----------|
| **Pillar** | One of the 4 security focus areas (authn-authz, data-protection, input-validation, audit-resilience). Each pillar has one subagent. |
| **Subagent** | A specialised reviewer that analyses code against one pillar's checklist. Runs in parallel with the other 3. |
| **Skill orchestrator** | The `/review-security` skill that dispatches subagents, collects results, deduplicates, and synthesises the final report. |
| **Synthesis** | The process of merging 4 subagent reports into one consolidated maturity assessment. |
| **Deduplication** | When two subagents flag the same file:line, merging into one finding with the highest severity and most restrictive maturity tag. |

## Output Terms

| Term | Definition |
|------|-----------|
| **Finding** | A single identified vulnerability: severity, maturity level, confidence, STRIDE category, file location, description, exploit scenario, and recommendation. |
| **Exploit scenario** | A concrete description of how an attacker would exploit the vulnerability. Required for every finding. |
| **Maturity assessment** | Per-criterion evaluation (met/not met/partially met) for each maturity level. |
| **Immediate action** | The single most important thing to fix. Hygiene failure if any exist, otherwise the top finding from the next achievable level. |
