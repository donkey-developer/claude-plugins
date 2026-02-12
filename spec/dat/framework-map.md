# Framework Map -- Pillars, Quality Dimensions, and Decay Patterns

> How the three analytical layers in the Data domain relate to each other. Use this map when writing or reviewing prompts to ensure coverage is complete and lenses are applied correctly.

## The Duality: Decay Patterns attack, Quality Dimensions defend

Every Decay Pattern has one or more Quality Dimensions that mitigate it. When a reviewer identifies a decay pattern problem, they should recommend strengthening the corresponding quality dimension.

| Decay Pattern | Primary Quality Dimension defence | Secondary defence | Why this pairing |
|---------------|----------------------------------|-------------------|-----------------|
| **Silent corruption** | **Accuracy** | Validity | Silent corruption produces wrong data that looks right; accuracy checks (reconciliation, source comparison) catch it; validity checks (constraints, ranges) prevent it at ingestion. |
| **Schema drift** | **Consistency** | Validity | Schema drift causes consumers to misinterpret data; consistency checks (cross-system comparisons, contract enforcement) detect it; validity checks (schema enforcement) prevent it. |
| **Ownership erosion** | **Completeness** | Accuracy | Without ownership, documentation and maintenance decay; completeness checks (metadata, field descriptions) surface the gaps; accuracy degrades as nobody validates the data against reality. |
| **Freshness degradation** | **Timeliness** | Completeness | Stale data leads to decisions on old information; timeliness checks (freshness SLOs, processing latency) detect it; completeness checks (expected row counts) catch missing loads. |
| **Compliance drift** | **Uniqueness** | Accuracy | Compliance drift creates uncontrolled data copies; uniqueness enforcement (primary keys, deduplication) prevents uncontrolled proliferation; accuracy (reconciliation) detects divergence between copies. |

### Using the duality in reviews

When writing a finding:
1. Identify the **Decay Pattern** (how the data is going wrong)
2. Check the **Quality Dimension defence** (what should protect against it)
3. If the defence is missing or insufficient, that's the finding
4. The recommendation should describe the quality dimension to strengthen, not a specific technique

Example:
- Decay Pattern: Silent corruption (fan-out join inflates metrics on line 47)
- Quality Dimension defence needed: Accuracy (aggregation verification)
- Finding: "1-to-many join inflates SUM(amount) -- each order counted once per line item"
- Recommendation: "Aggregate line_items first, then join to orders. Add reconciliation check comparing source and target totals."

## Pillar Focus Areas

Each pillar emphasises specific Quality Dimensions and Decay Patterns. This is not exclusive -- any pillar can flag any concern -- but these are the primary focus areas that each subagent should prioritise.

### Architecture pillar

**Mandate:** Is the data designed right?

| Decay Pattern focus | Why |
|---------------------|-----|
| Schema drift | Architecture owns schema design decisions. A column rename, type change, or semantic change is an architectural choice that cascades to all consumers. |
| Silent corruption | Deadly diamonds and cross-domain coupling are architectural flaws that produce silent corruption at the structural level. |

| Quality Dimension focus | Why |
|-------------------------|-----|
| Consistency | Schema design determines whether data is consistent across domains. Polysemes without global identifiers create systemic inconsistency. |
| Validity | Schema constraints, type choices, and normalisation decisions determine what data can exist. |

**Key review questions:**
- Does this data model adhere to its bounded context?
- Are shared concepts mapped using global identifiers?
- Is the schema appropriate for the use case (OLTP vs OLAP vs streaming)?
- Will downstream consumers break if this ships?

### Engineering pillar

**Mandate:** Is the data built right?

| Decay Pattern focus | Why |
|---------------------|-----|
| Silent corruption | Engineering bugs (wrong joins, NULL handling, non-deterministic functions) produce silent corruption at the logic level. This is the most dangerous decay pattern because the pipeline "runs successfully" while producing wrong data. |

| Quality Dimension focus | Why |
|-------------------------|-----|
| Validity | Engineering validates data at ingestion and transformation -- type checks, constraint enforcement, range validation. |
| Uniqueness | Engineering implements idempotency (MERGE, DELETE-INSERT, UPSERT) that prevents duplicates on re-runs. |
| Accuracy | Engineering ensures transformation logic produces correct results -- the right aggregations, correct join semantics, proper NULL handling. |

**Key review questions:**
- Is the transformation idempotent?
- Are there tests for edge cases (NULLs, empty sets, fan-out)?
- Can processing resume without duplicates or gaps after failure?
- What happens when incoming data fails validation?

### Quality pillar

**Mandate:** Does the data meet expectations?

| Decay Pattern focus | Why |
|---------------------|-----|
| Freshness degradation | Quality owns timeliness. If data is late, stale, or missing, consumers make decisions on outdated information. |
| Ownership erosion | Quality owns usability. If data is undocumented, undiscoverable, or full of tribal knowledge, it fails the consumer regardless of correctness. |

| Quality Dimension focus | Why |
|-------------------------|-----|
| Timeliness | Freshness SLOs, processing latency, appropriate update frequency. |
| Completeness | Expected row counts, required fields not NULL, no missing loads. |
| Accuracy | Reconciliation between source and target. Bitemporality for audit-critical data. |

**Key review questions:**
- If this data is wrong, how would we know?
- What's the freshness SLO? Is it documented?
- Can a new team member understand this data without asking someone?
- What happens if source data arrives late?

### Governance pillar

**Mandate:** Is the data managed right?

| Decay Pattern focus | Why |
|---------------------|-----|
| Compliance drift | Governance owns regulatory compliance. PII exposure, missing retention policies, and absent lifecycle management create legal and reputational risk. |
| Ownership erosion | Governance owns accountability. Without clear business and technical owners, data becomes orphaned. |

| Quality Dimension focus | Why |
|-------------------------|-----|
| Completeness | Governance verifies that required metadata is present: classification, ownership, retention policy, lineage. |
| Accuracy | Governance verifies that lineage is correct -- data can be traced from source to destination through all transformations. |

**Key review questions:**
- What happens if a user requests their data be deleted?
- If this data was leaked, what would be the impact?
- Who do I contact if I have questions about this data?
- Can we trace this data back to its original source?

## Coverage Matrix

This matrix shows which Decay Pattern / Quality Dimension combinations are covered by which pillar. Use it to verify that prompt changes don't create coverage gaps.

| | Silent corruption | Schema drift | Ownership erosion | Freshness degradation | Compliance drift |
|---|---|---|---|---|---|
| **Architecture** | Primary | Primary | - | - | - |
| **Engineering** | Primary | Secondary | - | - | - |
| **Quality** | - | - | Primary | Primary | - |
| **Governance** | - | - | Primary | - | Primary |

| | Accuracy | Completeness | Consistency | Timeliness | Validity | Uniqueness |
|---|---|---|---|---|---|---|
| **Architecture** | - | - | Primary | - | Primary | - |
| **Engineering** | Primary | - | - | - | Primary | Primary |
| **Quality** | Primary | Primary | - | Primary | - | - |
| **Governance** | Secondary | Primary | - | - | - | - |

**Key:** Primary = core focus area for this pillar. Secondary = reviewed but not the primary lens. `-` = not a focus area (may still be flagged if found).

## Inter-pillar Handoffs

When a finding spans pillars, the subagent that discovers it should flag it in their own pillar's terms. The synthesis step deduplicates across pillars.

Common handoff scenarios:

| Scenario | Discovered by | Also relevant to |
|----------|---------------|------------------|
| Schema change that breaks consumers AND introduces data quality risk | Architecture | Quality (consumer impact), Engineering (migration correctness) |
| PII in a transformation that also has correctness issues | Engineering | Governance (compliance), Quality (trust) |
| Missing freshness SLO that also indicates unclear ownership | Quality | Governance (ownership documentation) |
| Unbounded table growth that is both a governance gap and a quality risk | Governance | Quality (performance degradation), Engineering (query cost) |

## Cross-Domain Overlaps

The Data domain intentionally overlaps with other review domains. Each domain applies its own lens.

| Concern | Data Review lens | Other domain lens |
|---------|-----------------|-------------------|
| Freshness SLOs | Quality pillar: "Is the data timely for consumers?" | SRE Availability: "Does the pipeline meet its SLO?" |
| Query performance | Engineering pillar: "Is the query cost appropriate?" | SRE Capacity: "Will this query exhaust shared resources?" |
| PII handling | Governance pillar: "Is PII classified and masked?" | Security Data-Protection: "Is PII encrypted and access-controlled?" |
| Lineage | Governance pillar: "Can we trace data to its source?" | Security Audit-Resilience: "Is there an audit trail?" |
| Schema migration | Architecture pillar: "Is this backward-compatible?" | SRE Delivery: "Can this be rolled back safely?" |
