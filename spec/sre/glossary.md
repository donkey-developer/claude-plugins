# Glossary — SRE Domain

> Canonical definitions for all terms, frameworks, and acronyms used in the SRE review domain. When writing or modifying prompts, use these definitions exactly.

## Frameworks

### ROAD

**Response, Observability, Availability, Delivery.** The structural framework that organises the SRE review into four pillars, each with a dedicated subagent.

Origin: Bruce Dominguez.

| Pillar | One-line mandate |
|--------|-----------------|
| **R**esponse | Can operators diagnose and recover from failures? |
| **O**bservability | Can we see what the system is doing in production? |
| **A**vailability | Does the system meet SLOs and degrade gracefully? |
| **D**elivery | Can we ship and roll back safely? |

### SEEMS

**Shared fate, Excessive load, Excessive latency, Misconfiguration, Single points of failure.** Five categories of failure modes. SEEMS is the "offensive" lens — it asks *"How will this code fail in production?"*

| Category | Definition | Recognition heuristic |
|----------|-----------|----------------------|
| **S**hared fate | Component coupling that causes correlated failures across otherwise-independent consumers. | Look for: shared DB, shared cache, shared queue, shared connection pool, shared thread pool serving multiple consumers. |
| **E**xcessive load | Patterns that amplify load under stress, turning a partial failure into a total one. | Look for: retry without backoff, fan-out without backpressure, unbounded parallelism, missing rate limits, no admission control. |
| **E**xcessive latency | Operations with unbounded execution time that block resources and breach SLOs. | Look for: missing timeouts on external calls, synchronous call chains, head-of-line blocking, full table scans, unbounded pagination. |
| **M**isconfiguration | Configuration errors that cause outages, especially those that are hard to diagnose. | Look for: hardcoded values that should be configurable, no startup validation, no fail-safe defaults, magic strings without documentation. |
| **S**ingle points of failure | Components with no redundancy whose failure causes total loss of function. | Look for: single-instance services, non-replicated state, no failover path, no fallback, unique hardware dependency. |

**Compounding rule:** SEEMS categories compound. Excessive load + Shared fate = cascading retry storms. Misconfiguration + Single point of failure = one typo takes down the only instance. Prompts should note when categories interact.

### FaCTOR

**Fault isolation, Availability, Capacity, Timeliness, Output correctness, Redundancy.** Six resilience properties that code should preserve. FaCTOR is the "defensive" lens — it asks *"What protects this code from failing in production?"*

| Property | What "good" looks like | What "bad" looks like |
|----------|----------------------|---------------------|
| **F**ault isolation | Failures stay within their boundary. Bulkheads exist between components. Error handling prevents cascade. | One component failure propagates through the system. Shared resources become a single point of coupling. |
| **A**vailability | System degrades gracefully. Partial functionality is preferred over total failure. Health checks reflect real readiness. | Binary mode: either fully working or completely down. Health checks are hardcoded or trivial. |
| **C**apacity | Load shedding exists. Backpressure mechanisms work. Resource limits are defined. Queue depths are bounded. | Unbounded work acceptance. No backpressure. Resources exhausted under load. |
| **T**imeliness | Operations have bounded latency. Timeouts are set appropriately. SLOs can be met under load. | P99 latency grows unbounded under stress. No timeouts. SLOs breached during normal peaks. |
| **O**utput correctness | Idempotent where needed. Delivery semantics (exactly-once, at-least-once) are explicit. Data consistency is maintained during failures. | Silent data corruption. Duplicate processing. Inconsistent state after partial failures. |
| **R**edundancy | No new single points of failure. Failover paths exist. State can be recovered after failure. | Single-instance critical paths. No failover. Unrecoverable state after restart. |

### SEEMS-FaCTOR Duality

Every SEEMS failure mode has a corresponding FaCTOR property that mitigates it. See `framework-map.md` for the complete mapping.

## Maturity Model

### Hygiene Gate

A promotion gate that overrides maturity levels. Any finding at any level is promoted to `HYG` if it passes any of these three consequence-severity tests:

| Test | Question | SRE examples |
|------|----------|--------------|
| **Irreversible** | If this goes wrong, can the damage be undone? | Catch-all exception handler that returns success, masking data loss. Silent data corruption with no audit trail. |
| **Total** | Can this take down the entire service or cascade beyond its boundary? | Retry loop with no bound or backoff that can exhaust thread pools. Health check hardcoded to return healthy, routing traffic to dead instances. Missing timeout on external call that blocks the only worker thread. |
| **Regulated** | Does this violate a legal or compliance obligation? | PII logged to stdout without masking. Health data exposed in error responses. |

Any "yes" to any test = `HYG`. The Hygiene flag trumps all maturity levels.

### Maturity Levels

Levels are cumulative. Each requires the previous. See `maturity-criteria.md` for detailed criteria with thresholds.

| Level | Name | One-line description |
|-------|------|---------------------|
| **L1** | Foundations | The basics are in place. The system can be operated. |
| **L2** | Hardening | Production-ready practices. The system can be operated *well*. |
| **L3** | Excellence | Best-in-class. The system is a model for others. |

### Severity Levels

| Level | Production impact | Merge decision |
|-------|------------------|----------------|
| **HIGH** | Could cause outage, data loss, or significant degradation | Must fix before merge |
| **MEDIUM** | Operational risk that should be addressed | May require follow-up ticket |
| **LOW** | Minor improvement opportunity | Nice to have |

Severity measures **production consequence**, not implementation difficulty.

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
| **Pillar** | One of the 4 ROAD components (Response, Observability, Availability, Delivery). Each pillar has one subagent. |
| **Subagent** | A specialised reviewer that analyses code against one pillar's checklist. Runs in parallel with the other 3. |
| **Skill orchestrator** | The `/review-sre` skill that dispatches subagents, collects results, deduplicates, and synthesises the final report. |
| **Synthesis** | The process of merging 4 subagent reports into one consolidated maturity assessment. |
| **Deduplication** | When two subagents flag the same file:line, merging into one finding with the highest severity and most restrictive maturity tag. |

## Output Terms

| Term | Definition |
|------|-----------|
| **Finding** | A single identified issue: severity, maturity level, SEEMS/FaCTOR category, file location, description, and recommendation. |
| **Maturity assessment** | Per-criterion evaluation (met/not met/partially met) for each maturity level. |
| **Immediate action** | The single most important thing to fix. Hygiene failure if any exist, otherwise the top finding from the next achievable level. |
