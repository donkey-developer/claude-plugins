# Create Architecture domain review

**Issue:** #22
**Branch:** feat/architecture-domain
**Depends on:** #19
**Brief ref:** BRIEF.md Sections 1-6

Follows the pattern established by the SRE reference implementation.

## Sources

- `spec/domains/architecture/spec.md` — Architecture specification index
- `spec/domains/architecture/anti-patterns.md` — anti-patterns with code examples
- `spec/domains/architecture/maturity-criteria.md` — Architecture-specific maturity criteria
- `spec/domains/architecture/framework-map.md` — C4 framework mapping
- `spec/domains/architecture/glossary.md` — Architecture-specific terms
- `spec/domains/architecture/calibration.md` — calibration guidance
- Spike cross-reference (advisory): `https://github.com/LeeCampbell/code-review-llm` → `.claude/prompts/architecture/`

## Domain-specific notes

- **C4 zoom levels** — Code, Service, System, Landscape at increasing scope
- **Principles/Erosion duality** — Design Principles (what should this look like?) vs Erosion Patterns (how does this go wrong?)
- **Adaptive to project size** — Landscape and System may return "no findings" on small projects; this is correct, not a gap
- **Design-time focus** — Evaluates decisions, not just implementation ("is this the right pattern?" not "is it configured?")
- **Do NOT prescribe patterns by name** — Describe structural properties, not "use DDD" or "use Clean Architecture"
- **All 4 agents use sonnet** — all levels require nuanced design judgement

## Tasks

- [x] **TASK-01: Create Architecture _base.md**
  - **Goal:** Distil the Architecture domain foundation into a base prompt covering C4 zoom levels, principles/erosion duality, maturity criteria, and glossary
  - **Brief ref:** BRIEF.md Section 6 (domain `_base.md`: ~200-250 lines)
  - **Files:**
    - Create `plugins/code-review/prompts/architecture/_base.md`
  - **Spec ref:** `spec/domains/architecture/spec.md`, `spec/domains/architecture/framework-map.md`, `spec/domains/architecture/maturity-criteria.md`, `spec/domains/architecture/glossary.md`
  - **Details:**
    - Purpose statement (what Architecture review evaluates)
    - C4 zoom levels overview (Code → Service → System → Landscape)
    - Principles/Erosion duality (design principles attack lens / erosion patterns defence lens)
    - Adaptive scaling — "no findings" is valid at higher zoom levels for smaller projects
    - Design-time vs run-time distinction (Architecture owns design-time; SRE owns run-time)
    - Domain-specific maturity criteria
    - Architecture glossary
    - `## Review Instructions` section with Design Principles/Erosion Patterns lens names
    - No domain-specific synthesis rules for Architecture (note explicitly)
  - **Verification:** File exists; ~200-250 lines; covers C4, duality, adaptive scaling; has Review Instructions

- [x] **TASK-02: Create Architecture code.md pillar prompt**
  - **Goal:** Create the Code zoom-level pillar prompt with focus areas, anti-patterns, and checklist
  - **Brief ref:** BRIEF.md Section 6 (pillar prompts: ~80-120 lines)
  - **Files:**
    - Create `plugins/code-review/prompts/architecture/code.md`
  - **Spec ref:** `spec/domains/architecture/anti-patterns.md` (Code-level patterns), `spec/domains/architecture/calibration.md`
  - **Details:** SOLID compliance (describe properties, not acronyms), coupling/cohesion, naming, testability. Describe structural properties, not pattern names.
  - **Verification:** File exists; ~80-120 lines; does NOT prescribe patterns by name; has checklist

- [x] **TASK-03: Create Architecture service.md pillar prompt**
  - **Goal:** Create the Service zoom-level pillar prompt with focus areas, anti-patterns, and checklist
  - **Files:**
    - Create `plugins/code-review/prompts/architecture/service.md`
  - **Spec ref:** `spec/domains/architecture/anti-patterns.md` (Service-level patterns), `spec/domains/architecture/calibration.md`
  - **Details:** Bounded context alignment, layering violations, deployability, API design, dependency direction.
  - **Verification:** File exists; ~80-120 lines; has checklist

- [x] **TASK-04: Create Architecture system.md pillar prompt**
  - **Goal:** Create the System zoom-level pillar prompt with focus areas, anti-patterns, and checklist
  - **Files:**
    - Create `plugins/code-review/prompts/architecture/system.md`
  - **Spec ref:** `spec/domains/architecture/anti-patterns.md` (System-level patterns), `spec/domains/architecture/calibration.md`
  - **Details:** Inter-service coupling, stability patterns, data flow, integration patterns. May return "no findings" for monoliths.
  - **Verification:** File exists; ~80-120 lines; has checklist

- [ ] **TASK-05: Create Architecture landscape.md pillar prompt**
  - **Goal:** Create the Landscape zoom-level pillar prompt with focus areas, anti-patterns, and checklist
  - **Files:**
    - Create `plugins/code-review/prompts/architecture/landscape.md`
  - **Spec ref:** `spec/domains/architecture/anti-patterns.md` (Landscape-level patterns), `spec/domains/architecture/calibration.md`
  - **Details:** Governance, context maps, ADR traceability, technology radar alignment. Most likely to return "no findings" on smaller projects.
  - **Verification:** File exists; ~80-120 lines; has checklist

- [ ] **TASK-06: Add Architecture entries to compile.conf**
  - **Goal:** Add the 4 Architecture agent entries and 1 Architecture skill entry to compile.conf
  - **Files:**
    - Edit `plugins/code-review/prompts/compile.conf`
  - **Details:**
    - `architecture-code`: model=sonnet
    - `architecture-service`: model=sonnet
    - `architecture-system`: model=sonnet
    - `architecture-landscape`: model=sonnet
    - `architecture` skill entry
  - **Verification:** compile.conf has 4 Architecture agent entries (all sonnet) and 1 Architecture skill entry

- [ ] **TASK-07: Run compile.sh and verify generated files**
  - **Goal:** Generate the 4 Architecture agent files and the Architecture skill file from prompts
  - **Files generated:**
    - `plugins/code-review/agents/architecture-code.md`
    - `plugins/code-review/agents/architecture-service.md`
    - `plugins/code-review/agents/architecture-system.md`
    - `plugins/code-review/agents/architecture-landscape.md`
    - `plugins/code-review/skills/architecture/SKILL.md`
  - **Verification:**
    - `scripts/compile.sh` exits 0
    - All 5 files exist with correct frontmatter (all sonnet)
    - No pattern names prescribed in agent content
    - `scripts/compile.sh --check` exits 0

- [ ] **TASK-08: Final verification**
  - **Goal:** Verify the complete Architecture domain is correctly built
  - **Verification:**
    - 5 prompt source files exist in `prompts/architecture/`
    - 4 agent files exist in `agents/` with correct frontmatter (all sonnet)
    - 1 skill file exists in `skills/architecture/SKILL.md`
    - No pattern names prescribed (grep for "use DDD", "use Clean Architecture", etc.)
    - Adaptive scaling noted in agent prompts
    - `compile.sh --check` confirms sync
