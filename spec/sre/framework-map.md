# Framework Map — SEEMS, FaCTOR, and ROAD

> How the three SRE frameworks relate to each other. Use this map when writing or reviewing prompts to ensure coverage is complete and lenses are applied correctly.

## The Duality: SEEMS attacks, FaCTOR defends

Every SEEMS failure mode has one or more FaCTOR properties that mitigate it. When a reviewer identifies a SEEMS problem, they should recommend strengthening the corresponding FaCTOR property.

| SEEMS failure mode | Primary FaCTOR defence | Secondary FaCTOR defence | Why this pairing |
|--------------------|----------------------|------------------------|-----------------|
| **Shared fate** | **Fault isolation** | Redundancy | Shared fate creates coupling; fault isolation (bulkheads) breaks coupling; redundancy ensures one path remains. |
| **Excessive load** | **Capacity** | Fault isolation | Excessive load overwhelms resources; capacity controls (load shedding, backpressure) bound the damage; fault isolation prevents spillover. |
| **Excessive latency** | **Timeliness** | Availability | Excessive latency breaches SLOs; timeliness (timeouts, bounded operations) caps the damage; availability (graceful degradation) serves partial results. |
| **Misconfiguration** | **Output correctness** | Fault isolation | Misconfig produces wrong behaviour; output correctness (validation, fail-safe defaults) catches it; fault isolation limits the blast radius. |
| **Single points of failure** | **Redundancy** | Availability | SPOFs mean one failure = total loss; redundancy provides failover; availability ensures degraded-but-running over down. |

### Using the duality in reviews

When writing a finding:
1. Identify the **SEEMS category** (how the code fails)
2. Check the **FaCTOR defence** (what should protect against it)
3. If the defence is missing or insufficient, that's the finding
4. The recommendation should describe the FaCTOR property to strengthen, not a specific technique

Example:
- SEEMS: Excessive load (retry without backoff on line 47)
- FaCTOR defence needed: Capacity (bounded retries with backoff)
- Finding: "Unbounded retry on dependency failure can amplify load under stress"
- Recommendation: "Bound retry count and add exponential backoff with jitter to prevent load amplification"

## ROAD Pillar Focus Areas

Each ROAD pillar emphasises specific SEEMS/FaCTOR elements. This is not exclusive — any pillar can flag any category — but these are the primary focus areas that each subagent should prioritise.

### Response pillar

**Mandate:** Can operators diagnose and recover from failures?

| SEEMS focus | Why |
|-------------|-----|
| Misconfiguration | Config errors are the #1 cause of operator confusion during incidents. If the error message doesn't distinguish "wrong config" from "dependency down", MTTR increases. |
| Shared fate | When a shared dependency fails, operators need to know *which* dependency and *why*. Ambiguous failure attribution extends incidents. |
| Excessive latency | Timeout errors need context about what was being waited on and how long. "Request timed out" without details is useless at 3am. |

| FaCTOR focus | Why |
|--------------|-----|
| Fault isolation | Failures must be attributed to the correct component. If errors propagate without source attribution, operators chase the wrong service. |
| Output correctness | Error responses must be well-formed and follow API contracts. Malformed errors break client error handling and confuse automated alerting. |

### Observability pillar

**Mandate:** Can we see what the system is doing in production?

| SEEMS focus | Why |
|-------------|-----|
| Excessive load | If load isn't visible (request rates, queue depths), operators can't see overload developing until it's too late. |
| Excessive latency | If latency percentiles aren't captured, slow dependencies are invisible until they breach SLOs. |
| Misconfiguration | If config values aren't logged at startup or exposed as metrics, config-related failures are impossible to diagnose without code access. |

| FaCTOR focus | Why |
|--------------|-----|
| Capacity | Resource utilisation (connection pools, memory, CPU) must be visible to detect saturation before it causes failure. |
| Timeliness | Latency must be measurable against SLO targets. If you can't measure it, you can't alert on it. |

### Availability pillar

**Mandate:** Does the system meet SLOs and degrade gracefully?

This pillar has the broadest SEEMS/FaCTOR coverage because availability is the aggregate outcome of all resilience properties.

| SEEMS focus | Why |
|-------------|-----|
| Shared fate | Blast radius analysis. If this fails, what else fails? |
| Excessive load | What happens at 10x traffic? Retry storms? Fan-out amplification? |
| Excessive latency | Worst-case latency? Unbounded operations? |
| Single points of failure | Redundancy story? Failover paths? |

| FaCTOR focus | Why |
|--------------|-----|
| Fault isolation | Bulkheads between tenants, request types, dependencies. |
| Availability | Degraded mode design. Is "something" better than "nothing"? |
| Capacity | Limits defined? Load shedding? Admission control? |
| Redundancy | Failover path? Recovery time? Data loss during failover? |

### Delivery pillar

**Mandate:** Can we ship and roll back safely?

| SEEMS focus | Why |
|-------------|-----|
| Misconfiguration | A config change during deployment can cause outage. Safe defaults and validation matter most during rollout. |
| Shared fate | Coordinated multi-service deployments create shared fate. One service's deployment failure shouldn't block others. |

| FaCTOR focus | Why |
|--------------|-----|
| Output correctness | During rollout, old and new versions coexist. Both must produce consistent results or users see inconsistent behaviour. |
| Availability | Deployment must not cause downtime. Rollback must not cause data loss. |

## Coverage Matrix

This matrix shows which SEEMS/FaCTOR combinations are covered by which ROAD pillar. Use it to verify that prompt changes don't create coverage gaps.

| | Shared fate | Excessive load | Excessive latency | Misconfiguration | SPOF |
|---|---|---|---|---|---|
| **Response** | Primary | - | Secondary | Primary | - |
| **Observability** | - | Primary | Primary | Secondary | - |
| **Availability** | Primary | Primary | Primary | - | Primary |
| **Delivery** | Secondary | - | - | Primary | - |

| | Fault isolation | Availability | Capacity | Timeliness | Output correctness | Redundancy |
|---|---|---|---|---|---|---|
| **Response** | Primary | - | - | - | Primary | - |
| **Observability** | - | - | Primary | Primary | - | - |
| **Availability** | Primary | Primary | Primary | - | - | Primary |
| **Delivery** | - | Secondary | - | - | Primary | - |

**Key:** Primary = core focus area for this pillar. Secondary = reviewed but not the primary lens. `-` = not a focus area (may still be flagged if found).

## Inter-pillar Handoffs

When a finding spans pillars, the subagent that discovers it should flag it in their own pillar's terms. The synthesis step deduplicates across pillars.

Common handoff scenarios:

| Scenario | Discovered by | Also relevant to |
|----------|---------------|------------------|
| Missing timeout causes both unobservable latency and availability risk | Observability or Availability | Both — deduplicate during synthesis |
| Error message quality affects both incident response and observability | Response | Observability (if the error doesn't emit a metric/log) |
| Database migration affects both deployment safety and availability | Delivery | Availability (if migration causes downtime) |
| Health check quality affects both response (diagnosability) and availability (traffic routing) | Availability | Response |
