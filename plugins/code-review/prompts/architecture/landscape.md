## Landscape Level — Does It Fit the Wider Ecosystem?

The Landscape level examines how multiple systems, teams, and organisations interact — their boundaries, integration strategies, decision traceability, and technology alignment.
It evaluates whether the ecosystem's cross-system architecture supports independent evolution and intentional governance.
For smaller projects or monoliths, this level may return "no findings" — that is correct, not a gap.

## Focus Areas

- **Boundary clarity across systems** — bounded contexts and their relationships are documented and explicit.
  Flag systems with no visible boundaries, no context map, or no relationship documentation.
- **Integration patterns** — cross-system communication uses appropriate patterns (event-based, request-response) with documented message formats.
  Flag undocumented integration points, point-to-point connections without mediation, missing dead-letter or error handling.
- **Decision traceability** — significant architectural decisions are documented with rationale and trade-offs.
  Flag major technology choices with no recorded rationale, stale specs that no longer match the codebase.
- **Technology consistency** — technology choices are intentional and justified, not accidental.
  Flag the same problem solved with different technologies with no rationale, or one technology forced into every use case.
- **Evolutionary readiness** — the architecture can evolve incrementally without big-bang rewrites.
  Flag coordinated deployment requirements, lack of deprecation or migration patterns, no automated architectural validation.

## Anti-Patterns

### LL-01: Distributed big ball of mud

No clear boundaries between systems.
Everything calls everything.
Any change requires coordinating across many teams.
**Principle:** Separation of Concerns, Explicit over Implicit | **Severity:** HIGH / L1

### LL-02: Undocumented integration points

Services connected with no formal contract.
No OpenAPI, no AsyncAPI, no documented message formats.
**Principle:** Explicit over Implicit | **Severity:** HIGH / L1

### LL-03: Shared database across system boundaries

Multiple systems (owned by different teams or organisations) writing to the same database.
**Principle:** Loose Coupling | **Severity:** HIGH / HYG

### LL-04: Missing ADRs for significant decisions

Major technology or architecture choices with no documented rationale.
**Principle:** Explicit over Implicit | **Severity:** MEDIUM / L2

### LL-05: Stale documentation / design-code drift

Design docs that do not match the current codebase.
ADRs accepted but tech-spec unchanged.
**Principle:** Explicit over Implicit | **Severity:** MEDIUM / L2

### LL-06: Spaghetti integration

Point-to-point connections everywhere.
N services with N*(N-1)/2 direct connections.
No event bus, no API gateway, no shared messaging infrastructure.
**Principle:** Loose Coupling | **Severity:** MEDIUM / L2

### LL-07: Golden hammer

Same technology for every problem — forces inappropriate design patterns.
**Principle:** Separation of Concerns | **Severity:** MEDIUM / L2

### LL-08: No fitness functions

Architecture standards exist on paper but are not enforced.
No automated tests for layer violations, circular dependencies, API compatibility, or performance budgets.
**Principle:** Explicit over Implicit | **Severity:** LOW / L3 (escalates to MEDIUM if standards exist but are not enforced)

## Checklist

- [ ] Are system boundaries documented with a context map or equivalent?
- [ ] Do cross-system integration points have formal contracts (OpenAPI, AsyncAPI, Protobuf)?
- [ ] Are there systems sharing a database across organisational or team boundaries?
- [ ] Do significant architectural decisions have recorded rationale and trade-offs (ADRs or equivalent)?
- [ ] Does design documentation match the current state of the codebase?
- [ ] Are integration patterns appropriate for the communication style (event-based vs request-response)?
- [ ] Can systems be deployed and evolved independently without coordinated releases?
- [ ] Are technology choices intentional and justified, not duplicated or forced into every use case?
- [ ] Do deprecation and migration patterns exist for retiring old systems or components?
- [ ] Are architectural constraints validated automatically in CI (fitness functions)?

## Positive Indicators

- Context map exists showing all system boundaries and their relationship types.
- Significant architectural decisions documented with rationale, trade-offs, and review history.
- Cross-system integration points use formal contracts with versioning and compatibility checks.
- Systems can evolve independently with documented deprecation and migration strategies.
