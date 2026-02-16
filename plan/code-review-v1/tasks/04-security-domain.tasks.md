# Create Security domain review

**Issue:** #21
**Branch:** feat/security-domain
**Depends on:** #19
**Brief ref:** BRIEF.md Sections 1-6

Follows the pattern established by the SRE reference implementation.

## Sources

- `spec/domains/security/spec.md` — Security specification index
- `spec/domains/security/anti-patterns.md` — anti-patterns with code examples
- `spec/domains/security/maturity-criteria.md` — Security-specific maturity criteria
- `spec/domains/security/framework-map.md` — STRIDE framework mapping
- `spec/domains/security/glossary.md` — Security-specific terms
- `spec/domains/security/calibration.md` — calibration guidance
- Spike cross-reference (advisory): `https://github.com/LeeCampbell/code-review-llm` → `.claude/prompts/security/`

## Domain-specific notes

- **STRIDE framework**, threat/property duality
- **Confidence thresholds:** Remove findings below 50% confidence before deduplication (HIGH >80%, MEDIUM 50-80%, LOW <50% → do not report)
- **Exploit path required** for every finding — vulnerability without exploit path is theoretical, not a finding
- **Explicit exclusion list:** No dependency scanning, no secret scanning from git history, no penetration testing
- **Tampering boundary rule:** Must be within code boundary, not infrastructure

## Tasks

- [ ] **TASK-01: Create Security _base.md**
  - **Goal:** Distil the Security domain foundation into a base prompt covering STRIDE framework, threat/property duality, confidence thresholds, and glossary
  - **Brief ref:** BRIEF.md Section 6 (domain `_base.md`: ~200-250 lines)
  - **Files:**
    - Create `plugins/code-review/prompts/security/_base.md`
  - **Spec ref:** `spec/domains/security/spec.md`, `spec/domains/security/framework-map.md`, `spec/domains/security/maturity-criteria.md`, `spec/domains/security/glossary.md`
  - **Details:**
    - Purpose statement (what Security review evaluates)
    - STRIDE overview (6 threat categories distributed across 4 pillars)
    - Threat/Property duality (STRIDE Threats attack lens / Security Properties defence lens)
    - Confidence thresholds (HIGH >80%, MEDIUM 50-80%, LOW <50%)
    - Exclusion list (dependency scanning, secret scanning, penetration testing)
    - Domain-specific maturity criteria
    - Security glossary
    - `## Review Instructions` section with STRIDE Threats/Security Properties lens names
    - `## Synthesis Pre-filter` section: confidence filter (remove <50% before dedup)
  - **Verification:** File exists; ~200-250 lines; covers STRIDE, confidence thresholds, exclusion list; has synthesis pre-filter section

- [ ] **TASK-02: Create Security authn-authz.md pillar prompt**
  - **Goal:** Create the Authentication & Authorisation pillar prompt with focus areas, anti-patterns, and checklist
  - **Brief ref:** BRIEF.md Section 6 (pillar prompts: ~80-120 lines)
  - **Files:**
    - Create `plugins/code-review/prompts/security/authn-authz.md`
  - **Spec ref:** `spec/domains/security/anti-patterns.md` (AuthN/AuthZ patterns), `spec/domains/security/calibration.md`
  - **Details:** STRIDE categories: Spoofing, Elevation of Privilege. Covers authentication bypass patterns, privilege escalation, session management, token handling. Each finding must include exploit scenario.
  - **Verification:** File exists; ~80-120 lines; includes anti-patterns with exploit scenarios; has checklist

- [ ] **TASK-03: Create Security data-protection.md pillar prompt**
  - **Goal:** Create the Data Protection pillar prompt with focus areas, anti-patterns, and checklist
  - **Files:**
    - Create `plugins/code-review/prompts/security/data-protection.md`
  - **Spec ref:** `spec/domains/security/anti-patterns.md` (Data Protection patterns), `spec/domains/security/calibration.md`
  - **Details:** STRIDE categories: Information Disclosure, Tampering. Covers crypto usage, secrets exposure, data classification, at-rest/in-transit encryption. Tampering must be within code boundary.
  - **Verification:** File exists; ~80-120 lines; includes anti-patterns with exploit scenarios; has checklist

- [ ] **TASK-04: Create Security input-validation.md pillar prompt**
  - **Goal:** Create the Input Validation pillar prompt with focus areas, anti-patterns, and checklist
  - **Files:**
    - Create `plugins/code-review/prompts/security/input-validation.md`
  - **Spec ref:** `spec/domains/security/anti-patterns.md` (Input Validation patterns), `spec/domains/security/calibration.md`
  - **Details:** STRIDE categories: Tampering, Denial of Service. Covers injection patterns (SQL, XSS, command), deserialisation, file upload, regex DoS. Framework-aware — note when frameworks handle validation.
  - **Verification:** File exists; ~80-120 lines; includes anti-patterns with exploit scenarios; has checklist

- [ ] **TASK-05: Create Security audit-resilience.md pillar prompt**
  - **Goal:** Create the Audit & Resilience pillar prompt with focus areas, anti-patterns, and checklist
  - **Files:**
    - Create `plugins/code-review/prompts/security/audit-resilience.md`
  - **Spec ref:** `spec/domains/security/anti-patterns.md` (Audit & Resilience patterns), `spec/domains/security/calibration.md`
  - **Details:** STRIDE categories: Repudiation, Denial of Service. Covers audit logging, rate limiting, circuit breakers, error handling (information leakage). Binary checklist nature (present/absent).
  - **Verification:** File exists; ~80-120 lines; includes anti-patterns; has checklist

- [ ] **TASK-06: Add Security entries to compile.conf**
  - **Goal:** Add the 4 Security agent entries and 1 Security skill entry to compile.conf
  - **Files:**
    - Edit `plugins/code-review/prompts/compile.conf`
  - **Details:**
    - `security-authn-authz`: model=sonnet
    - `security-data-protection`: model=sonnet
    - `security-input-validation`: model=sonnet
    - `security-audit-resilience`: model=haiku
    - `security` skill entry
  - **Verification:** compile.conf has 4 Security agent entries with correct models and 1 Security skill entry

- [ ] **TASK-07: Run compile.sh and verify generated files**
  - **Goal:** Generate the 4 Security agent files and the Security skill file from prompts
  - **Files generated:**
    - `plugins/code-review/agents/security-authn-authz.md`
    - `plugins/code-review/agents/security-data-protection.md`
    - `plugins/code-review/agents/security-input-validation.md`
    - `plugins/code-review/agents/security-audit-resilience.md`
    - `plugins/code-review/skills/security/SKILL.md`
  - **Verification:**
    - `scripts/compile.sh` exits 0
    - All 5 files exist with correct frontmatter and inlined content
    - Security skill includes confidence filter in synthesis rules
    - `scripts/compile.sh --check` exits 0

- [ ] **TASK-08: Final verification**
  - **Goal:** Verify the complete Security domain is correctly built
  - **Verification:**
    - 5 prompt source files exist in `prompts/security/`
    - 4 agent files exist in `agents/` with correct frontmatter
    - 1 skill file exists in `skills/security/SKILL.md`
    - Confidence filter present in skill synthesis rules
    - Exclusion list present in agent prompts
    - Exploit path requirement present in agent prompts
    - `compile.sh --check` confirms sync
