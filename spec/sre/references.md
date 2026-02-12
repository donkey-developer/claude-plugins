# References -- SRE Domain

> Source attribution for all frameworks, concepts, and terminology used in the SRE review domain. Cite these when asked about the origin of a concept. Update this file when new sources are introduced.
>
> For shared project history and cross-domain references, see `../review-standards/references.md`.

## Framework Origins

### ROAD (Response, Observability, Availability, Delivery)

**Origin:** Bruce Dominguez
**Status:** External framework adopted as the structural backbone of the SRE review domain.
**How it's used:** Organises the SRE review into 4 pillars, each with a dedicated subagent. Every SRE review runs all 4 pillars in parallel.

### SEEMS (Shared fate, Excessive load, Excessive latency, Misconfiguration, Single points of failure)

**Origin:** To be confirmed. The acronym and categories appear to derive from common SRE failure taxonomy. If this is original to the project, declare it as such. If it comes from a specific author or publication, cite here.
**Status:** Used as the "offensive" analytical lens -- identifies how code can fail.
**How it's used:** Each ROAD pillar focuses on specific SEEMS categories (see `framework-map.md`). Findings are categorised by SEEMS failure mode.

### FaCTOR (Fault isolation, Availability, Capacity, Timeliness, Output correctness, Redundancy)

**Origin:** To be confirmed. Similar attribution question as SEEMS.
**Status:** Used as the "defensive" analytical lens -- verifies resilience properties.
**How it's used:** Paired with SEEMS to form the duality (attack/defence). Recommendations suggest strengthening specific FaCTOR properties.

## Books and Publications

### Site Reliability Engineering (Google SRE Book)

**Authors:** Betsy Beyer, Chris Jones, Jennifer Petoff, Niall Richard Murphy
**Published:** 2016, O'Reilly Media
**ISBN:** 978-1491929124
**Relevance:** Foundational SRE concepts -- SLOs, error budgets, toil reduction, incident response, postmortem culture. Informs the Availability and Response pillars.
**Specific chapters referenced:**
- Chapter 4: Service Level Objectives
- Chapter 6: Monitoring Distributed Systems
- Chapter 14: Managing Incidents
- Chapter 21: Handling Overload

### The Site Reliability Workbook

**Authors:** Betsy Beyer, Niall Richard Murphy, David K. Rensin, Kent Kawahara, Stephen Thorne
**Published:** 2018, O'Reilly Media
**ISBN:** 978-1492029502
**Relevance:** Practical implementation guidance for SLOs, alerting, and on-call. Informs maturity criteria definitions.

### Release It! (2nd Edition)

**Authors:** Michael T. Nygard
**Published:** 2018, Pragmatic Bookshelf
**ISBN:** 978-1680502398
**Relevance:** Stability patterns (circuit breakers, bulkheads, timeouts, governors) and anti-patterns (cascading failures, blocked threads, integration point failures). Directly informs the Availability pillar and the SEEMS/FaCTOR categories.
**Specific patterns referenced:**
- Circuit Breaker (Chapter 5)
- Bulkhead (Chapter 5)
- Timeout (Chapter 5)
- Steady State (Chapter 5)
- Fail Fast (Chapter 5)
- Handshaking (Chapter 5)
- Governor (Chapter 5)

### Implementing Service Level Objectives

**Authors:** Alex Hidalgo
**Published:** 2020, O'Reilly Media
**ISBN:** 978-1492076810
**Relevance:** Deep guidance on SLI selection, SLO definition, error budget policies. Informs L2 maturity criteria around SLO measurability.

### Observability Engineering

**Authors:** Charity Majors, Liz Fong-Jones, George Miranda
**Published:** 2022, O'Reilly Media
**ISBN:** 978-1492076445
**Relevance:** Observability vs monitoring distinction, structured events, high-cardinality data. Informs the Observability pillar.

### Domain-Driven Design

**Authors:** Eric Evans
**Published:** 2003, Addison-Wesley
**ISBN:** 978-0321125217
**Relevance:** Bounded contexts, aggregate boundaries. Referenced in the Architecture domain but also relevant to SRE (service boundaries = failure boundaries).

## Standards and Industry References

### OWASP Top 10

**URL:** https://owasp.org/www-project-top-ten/
**Relevance:** Referenced primarily in the Security domain, but items like "Security Misconfiguration" and "Server-Side Request Forgery" have SRE overlap via the Misconfiguration SEEMS category.

### The Twelve-Factor App

**URL:** https://12factor.net/
**Relevance:** Config management (Factor III), backing services (Factor IV), logs as event streams (Factor XI). Informs the Delivery and Observability pillars.

Also referenced in `../review-standards/references.md` as a cross-domain resource.

### OpenTelemetry Specification

**URL:** https://opentelemetry.io/docs/specs/
**Relevance:** Defines the standard for metrics, logs, and traces. The Observability pillar's checklist items (structured logging, span attributes, metric types) align with OpenTelemetry conventions without requiring it specifically.

## Domain-Specific Project History

Key PRs that shaped the SRE domain specifically:

| PR | What changed | Design impact |
|----|-------------|---------------|
| #3 | Initial SRE review system | Established ROAD + SEEMS/FaCTOR architecture, 4 subagents, prompt structure |
| #17 | "SPOF" renamed to "Single points of failure" | Terminology consistency with SEEMS framework definition |

For cross-domain PRs (#18, #19, #21, #23), see `../review-standards/references.md`.

## Attribution Gaps

The following require source confirmation:

| Term | Current status | Action needed |
|------|---------------|---------------|
| SEEMS | Used throughout prompts, no citation | Confirm if original to Bruce Dominguez / ROAD framework, or from another source |
| FaCTOR | Used throughout prompts, no citation | Same -- confirm origin |
| ROAD | Attributed to Bruce Dominguez in PR #3 | Confirm specific publication or talk |
