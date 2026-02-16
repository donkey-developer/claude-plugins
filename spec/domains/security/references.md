# References — Security Domain

> Source attribution for all frameworks, concepts, and terminology used in the Security review domain. Cite these when asked about the origin of a concept. Update this file when new sources are introduced.
>
> For shared project history and cross-domain references, see `../../review-standards/references.md`.

## Framework Origins

### STRIDE (Spoofing, Tampering, Repudiation, Information Disclosure, Denial of Service, Elevation of Privilege)

**Origin:** Microsoft. Created by Loren Kohnfelder and Praerit Garg in 1999.
**Publication:** "The threats to our products" (internal Microsoft paper, 1999). Later formalised in Microsoft's Security Development Lifecycle (SDL).
**Reference:** Adam Shostack, "Threat Modeling: Designing for Security" (2014, Wiley, ISBN 978-1118809990) provides the most comprehensive treatment of STRIDE in practice.
**Status:** Industry-standard threat modelling framework. Used as the structural backbone of the Security review domain.
**How it's used:** Organises the Security review into 6 threat categories distributed across 4 pillars. Each finding is tagged with one or more STRIDE categories.

### DREAD (Damage, Reproducibility, Exploitability, Affected users, Discoverability)

**Origin:** Microsoft, developed alongside STRIDE as part of SDL.
**Status:** The full DREAD model is largely deprecated (Discoverability and Reproducibility proved too subjective). This project uses a simplified "DREAD-lite" variant with three factors: Damage, Exploitability, Affected scope.
**How it's used:** Informs severity judgement (HIGH/MEDIUM/LOW) but is not scored numerically. Reviewers assess each factor qualitatively.

## Books and Publications

### Threat Modeling: Designing for Security

**Author:** Adam Shostack
**Published:** 2014, Wiley
**ISBN:** 978-1118809990
**Relevance:** Definitive guide to STRIDE-based threat modelling. Provides methodology for systematic threat identification, which informs the pillar structure and checklist design.
**Specific concepts referenced:**
- STRIDE-per-element (applying STRIDE to each component in a data flow diagram)
- STRIDE-per-interaction (applying STRIDE to each data flow)
- Threat trees and mitigations

### The Web Application Hacker's Handbook (2nd Edition)

**Authors:** Dafydd Stuttard, Marcus Pinto
**Published:** 2011, Wiley
**ISBN:** 978-1118026472
**Relevance:** Practical web vulnerability exploitation techniques. Informs the "exploit scenario" requirement in findings and the input-validation pillar's checklist.
**Specific areas referenced:**
- SQL injection techniques and prevention
- Authentication and session management attacks
- Access control bypass patterns

### OWASP Testing Guide (v4)

**URL:** https://owasp.org/www-project-web-security-testing-guide/
**Relevance:** Provides systematic testing methodology for each vulnerability category. Informs the checklist structure (what to look for in each area).

### Application Security Verification Standard (ASVS)

**URL:** https://owasp.org/www-project-application-security-verification-standard/
**Relevance:** Provides a framework of security requirements and controls. The three ASVS levels (Level 1: Opportunistic, Level 2: Standard, Level 3: Advanced) informed the design of the L1/L2/L3 maturity criteria, though the specific criteria differ.

### Secure by Design

**Authors:** Dan Bergh Johnsson, Daniel Deogun, Daniel Sawano
**Published:** 2019, Manning
**ISBN:** 978-1617294358
**Relevance:** Applying domain-driven design to security. Informed the "outcomes over techniques" design principle — security as a design quality rather than a checklist.

## Standards and Industry References

### OWASP Top 10

**URL:** https://owasp.org/www-project-top-ten/
**Version referenced:** 2021
**Relevance:** Industry-standard ranking of web application vulnerability categories. The Security review's pillar structure covers all OWASP Top 10 categories:
- A01:2021 Broken Access Control -> authn-authz pillar
- A02:2021 Cryptographic Failures -> data-protection pillar
- A03:2021 Injection -> input-validation pillar
- A04:2021 Insecure Design -> cross-cutting (covered by maturity model)
- A05:2021 Security Misconfiguration -> cross-cutting
- A06:2021 Vulnerable and Outdated Components -> excluded (dependency scanning)
- A07:2021 Identification and Authentication Failures -> authn-authz pillar
- A08:2021 Software and Data Integrity Failures -> input-validation (deserialization) + data-protection (integrity)
- A09:2021 Security Logging and Monitoring Failures -> audit-resilience pillar
- A10:2021 Server-Side Request Forgery -> input-validation pillar

### Common Weakness Enumeration (CWE)

**URL:** https://cwe.mitre.org/
**Relevance:** Provides standardised identifiers for vulnerability types. While the Security review does not tag findings with CWE IDs (to keep output concise), the anti-patterns catalogue maps to known CWEs:
- CWE-89: SQL Injection (IV-01)
- CWE-78: OS Command Injection (IV-02)
- CWE-79: Cross-Site Scripting (IV-03)
- CWE-22: Path Traversal (IV-04)
- CWE-502: Deserialization of Untrusted Data (IV-05)
- CWE-798: Use of Hard-coded Credentials (DP-01, AA-05)
- CWE-862: Missing Authorization (AA-01)
- CWE-639: Authorization Bypass Through User-Controlled Key (AA-02)

### NIST Cybersecurity Framework

**URL:** https://www.nist.gov/cyberframework
**Relevance:** The five NIST functions (Identify, Protect, Detect, Respond, Recover) broadly align with the pillar structure. The Security review focuses primarily on Protect (authn-authz, data-protection, input-validation) and Detect (audit-resilience).

### The Twelve-Factor App

**URL:** https://12factor.net/
**Relevance:** Factor III (Config) informs the secrets management criteria (secrets from environment, not code). Factor XII (Admin processes) informs audit logging requirements.

Also referenced in `../../review-standards/references.md` as a cross-domain resource.

## Domain-Specific Project History

Key PRs that shaped the Security domain specifically:

| PR | What changed | Design impact |
|----|-------------|---------------|
| #4 | Initial Security review system | Established STRIDE + DREAD-lite architecture, 4 subagents, prompt structure. Stacked on #3 (SRE). |
| #17 | Fix input-validation deserialization severity | Separated always-unsafe (pickle/marshal) from loader-dependent (YAML/XML/JSON). Established that deserialization risk varies by mechanism. |

For cross-domain PRs (#18, #19, #21, #23), see `../../review-standards/references.md`.

## Attribution Gaps

The following require source confirmation:

| Term | Current status | Action needed |
|------|---------------|---------------|
| DREAD-lite | Simplified variant used without formal citation | Confirm whether this specific 3-factor variant (DEA) has been published elsewhere, or declare as original to this project |
| Confidence thresholds (>80%, 50-80%, <50%) | Used in all 4 agent files | Confirm whether these specific thresholds derive from an industry standard or are original calibration choices |
