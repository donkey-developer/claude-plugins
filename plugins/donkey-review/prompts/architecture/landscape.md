# Landscape

Are your systems governed, documented, and fit to evolve?

The Landscape zoom level evaluates the broadest architectural concerns: whether system boundaries are clear, whether design decisions are recorded, whether cross-system relationships are documented, and whether architectural standards are enforced rather than just aspirational.
When this zoom level is weak, systems drift apart silently, integration points break without warning, and critical decisions exist only in the memories of engineers who may no longer be on the team.

**Note for small and single-service projects:** The Landscape zoom level is most likely to return no findings on smaller projects.
A single-file script, a small application, or a self-contained service has no cross-system relationships to govern and no multi-team boundaries to document.
"No findings at this zoom level" is correct and expected for those codebases — do not fabricate governance concerns where they do not apply.

## Focus Areas

### Design Principles focus (what should this look like?)

- **Documented decisions** — Are significant architecture and technology choices recorded with the context that drove them, the alternatives that were considered, and the trade-offs that were accepted?
  A decision captured only in a meeting or a person's head is a decision that will be re-litigated, or silently reversed, when that person leaves.
- **Explicit cross-boundary relationships** — Are the relationships between systems documented, with clear ownership on each side and an explicit description of what each relationship provides?
  Implicit relationships become undocumented dependencies that break at the worst possible moment.
- **Documentation currency** — Does available documentation reflect the current state of the system?
  Stale documentation is not neutral — it actively misleads engineers who rely on it to make decisions.
- **Deliberate technology choices** — Is the portfolio of technologies used to solve similar problems bounded and intentional?
  Unbounded proliferation of similar tools increases the cognitive burden on every engineer who must work across systems.
- **Governance automation** — Are architectural standards verified automatically rather than maintained solely through manual review?
  Standards not enforced by tooling erode one pragmatic exception at a time.

### Erosion Patterns focus (how does this go wrong?)

- **Boundary dissolution** — System boundaries that were once clear become porous as teams take shortcuts.
  Eventually no clear boundary exists and change requires coordinating across every system simultaneously.
- **Relationship invisibility** — Integrations form without documentation of what is being exchanged or who is responsible.
  Breaking changes become invisible until they reach production.
- **Decision amnesia** — Significant choices accumulate without documentation.
  New engineers cannot distinguish intentional design from historical accident, and cannot safely revisit decisions that should be reconsidered.
- **Documentation rot** — Specifications and design documents diverge from the implementation they describe.
  The longer the drift continues, the less useful — and the more dangerous — the documentation becomes.
- **Unchecked technology sprawl** — Teams independently adopt similar tools without coordination.
  Operational burden grows across the estate while no single tool is supported well.

## Anti-Pattern Catalogue

### LL-01: Distributed big ball of mud

No clear boundaries between systems.
Every service calls every other service directly.
Cross-system relationships are undocumented, and change requires coordinating across many teams simultaneously.

**Why it matters:** Without explicit boundaries, there is no stable surface to test, version, or evolve independently.
Every change becomes a system-wide risk.
Design Principles: Explicit cross-boundary relationships (absent).
Erosion Pattern: Boundary dissolution.
Typical severity: HIGH / L1 or HYG.

### LL-02: Undocumented integration points

Services are connected with no formal description of the exchange — no documented message format, no versioning, no ownership.
"It just calls that endpoint."

**Why it matters:** Breaking changes cannot be detected before they reach production because there is no baseline to compare against.
A producer change that violates an unrecorded expectation is invisible until a consumer crashes at runtime.
Design Principles: Explicit cross-boundary relationships (absent).
Erosion Pattern: Relationship invisibility.
Typical severity: HIGH / L1.

### LL-03: Shared database across system boundaries

Multiple systems — owned by different teams or organisations — read from or write to the same database.
Data ownership disputes become inter-team conflicts about schema changes.

**Why it matters:** A schema change made for one system silently breaks all others with no API boundary to signal the risk.
Independent deployment becomes impossible: every schema change requires coordinating all owners simultaneously.
Design Principles: Explicit cross-boundary relationships (violated at the data layer).
Erosion Pattern: Boundary dissolution.
Typical severity: HIGH / HYG (Irreversible + Total).

### LL-04: Missing documentation for significant decisions

Major technology or architecture choices exist with no recorded rationale.
"Why did we choose this?" — nobody knows.
Decisions live in people's heads or in meeting notes nobody can find.

**Why it matters:** Without recorded context, engineers cannot distinguish intentional design from historical accident.
Good decisions get reversed because their rationale was never captured; bad decisions persist because nobody knows they were ever questioned.
Design Principles: Documented decisions (absent).
Erosion Pattern: Decision amnesia.
Typical severity: MEDIUM / L2.

### LL-05: Stale documentation — design-code drift

Technical specifications or design documents describe a system that no longer exists.
The implementation has evolved but the documentation has not.

**Why it matters:** Stale documentation is worse than no documentation because engineers who consult it are actively misled.
Decisions made on the basis of inaccurate documentation compound the drift further.
Design Principles: Documentation currency (violated).
Erosion Pattern: Documentation rot.
Typical severity: MEDIUM / L2.

### LL-06: Spaghetti integration

Point-to-point connections between every pair of services.
Each new service must connect directly to every existing service, creating N*(N-1)/2 integration paths across the estate.

**Why it matters:** Each direct connection is a dependency that must be maintained, versioned, and protected from failure independently.
The cost of adding a new service grows with the number of existing services, and failures propagate along undocumented paths.
Design Principles: Explicit cross-boundary relationships (unmanageable at scale).
Erosion Pattern: Boundary dissolution, Relationship invisibility.
Typical severity: MEDIUM / L2.

### LL-08: No fitness functions

Architectural standards exist in documentation or in the heads of senior engineers, but are not enforced automatically.
Layer violations, forbidden dependencies, and structural rules accumulate one pragmatic exception at a time.

**Why it matters:** Architecture that is not verified cannot be trusted.
Standards maintained only through manual review degrade silently between reviews, with no signal until the damage is significant.
Design Principles: Governance automation (absent).
Erosion Pattern: Unchecked proliferation.
Typical severity: LOW / L3.

## Review Checklist

When assessing the Landscape zoom level, work through each item in order.

1. **System boundaries** — Are the boundaries between systems clear and documented?
   Is ownership of each area of the system unambiguous, with a single team or party responsible for each boundary?
2. **Cross-boundary relationships** — Are the relationships between systems documented, with explicit descriptions of what each relationship provides and what each party is responsible for?
   Are integration points formally described rather than inferred from code?
3. **Decision documentation** — Are significant architecture and technology decisions documented with their context and rationale, not just their outcome?
   Can an engineer who was not present understand why a choice was made?
4. **Documentation currency** — Does available documentation reflect the current state of the system?
   Is there evidence of drift between what is documented and what is implemented?
5. **Technology diversity** — Is the number of technologies solving the same problem bounded and deliberate?
   Are technology choices documented with the rationale for adoption?
6. **Governance automation** — Are architectural standards verified automatically?
   Do structural rules rely solely on manual review to be maintained?

## Severity Framing

Severity for Landscape findings is about the breadth of impact and the reversibility of the structural problem.

- **Distributed big ball of mud and shared database across system boundaries** — These are systemic governance failures.
  They affect every change made to the system and cannot be corrected without significant coordinated effort.
  Typically HIGH / L1 or HYG (Irreversible + Total).
- **Undocumented integration points** — Breaking changes are invisible until they reach production.
  The absence of a formal description means there is no safety net for producer changes.
  Typically HIGH / L1.
- **Missing decision documentation and stale documentation** — Knowledge loss and actively misleading guidance.
  These findings compound over time as decisions made on false premises accumulate.
  Typically MEDIUM / L2.
- **Spaghetti integration** — Accidental coupling accumulates with each new service added.
  The cost is not immediate but grows predictably as the system expands.
  Typically MEDIUM / L2.
- **No fitness functions** — Architecture erodes without enforcement, but slowly.
  The finding is low severity because the consequences are gradual rather than immediate.
  Typically LOW / L3.
- **Small and single-service projects** — For projects with no cross-system relationships or multi-team governance requirements, many Landscape criteria simply do not apply.
  "No findings at this zoom level" is a valid and correct output — do not fabricate governance concerns for projects where they are not appropriate.
