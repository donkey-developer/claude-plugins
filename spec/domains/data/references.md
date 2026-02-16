# References — Data Domain

> Source attribution for all frameworks, concepts, and terminology used in the Data review domain. Cite these when asked about the origin of a concept. Update this file when new sources are introduced.
>
> For shared project history and cross-domain references, see `../../review-standards/references.md`.

## Framework Origins

### The Four Pillars (Architecture, Engineering, Quality, Governance)

**Origin:** Original to this project, synthesised from multiple sources.
**Status:** The structural backbone of the Data review domain. Organises the review into 4 pillars, each with a dedicated subagent.
**Design rationale:** The pillars map naturally to the concerns of different stakeholders: architects care about design, engineers care about code quality, consumers care about quality, and compliance teams care about governance.
**Derivation:**
- Architecture pillar draws from DAMA DMBOK (Data Modeling & Design) and Data Mesh (domain ownership, interoperability)
- Engineering pillar draws from general software engineering practice (testing, idempotency, performance)
- Quality pillar draws from DAMA DMBOK (Data Quality Management) and Data Mesh (data product quality guarantees)
- Governance pillar draws from DAMA DMBOK (Data Governance, Data Security) and Data Governance for Everyone

### Quality Dimensions (Accuracy, Completeness, Consistency, Timeliness, Validity, Uniqueness)

**Origin:** DAMA DMBOK — Data Management Body of Knowledge.
**Status:** Used as the "defensive" analytical lens — describes what makes data trustworthy.
**How it's used:** Each quality dimension maps to specific checklist items across pillars. Findings recommend strengthening specific quality dimensions. See `framework-map.md` for dimension-to-pillar mapping.

### Decay Patterns (Silent corruption, Schema drift, Ownership erosion, Freshness degradation, Compliance drift)

**Origin:** Original to this project, derived from observed failure modes in data systems.
**Status:** Used as the "offensive" analytical lens — describes how data products degrade over time.
**How it's used:** Paired with Quality Dimensions to form the duality (attack/defence). Findings are classified by decay pattern. See `framework-map.md` for the complete mapping.
**Design rationale (why these five):**
- **Silent corruption** — the most dangerous data failure because it's invisible. Drawn from industry experience with fan-out joins, type coercion, and NULL handling.
- **Schema drift** — the most common data breakage. Drawn from Data Mesh's emphasis on data contracts and interface stability.
- **Ownership erosion** — the root cause of most governance failures. Drawn from Data Governance for Everyone's emphasis on practical accountability.
- **Freshness degradation** — the most impactful quality failure for decision-making. Drawn from Data Mesh's data product quality guarantees.
- **Compliance drift** — the highest-risk failure for organisations. Drawn from GDPR/CCPA requirements and DAMA DMBOK governance principles.

## Books and Publications

### DAMA-DMBOK: Data Management Body of Knowledge (2nd Edition)

**Authors:** DAMA International
**Published:** 2017, Technics Publications
**ISBN:** 978-1634622349
**Relevance:** The foundational reference for data management practice. Defines the quality dimensions, governance principles, and data management knowledge areas that underpin the Data review domain.
**Specific areas referenced:**
- Chapter 3: Data Governance — Roles, policies, accountability structures
- Chapter 5: Data Modeling and Design — Schema design patterns, normalisation, dimensional modeling
- Chapter 6: Data Storage and Operations — Lifecycle management, retention, archiving
- Chapter 8: Data Integration and Interoperability — ETL, CDC, data contracts
- Chapter 13: Data Quality Management — Quality dimensions, measurement, monitoring

### Data Mesh: Delivering Data-Driven Value at Scale

**Author:** Zhamak Dehghani
**Published:** 2022, O'Reilly Media
**ISBN:** 978-1492092391
**Relevance:** Defines the data-as-product paradigm that shapes the Data review's consumer-first perspective. Introduces data product properties, domain ownership, and self-serve data infrastructure.
**Specific concepts referenced:**
- Data as a product (Chapter 5) — discoverable, addressable, trustworthy, self-describing, interoperable, secure
- Domain ownership (Chapter 4) — bounded contexts for data, polysemes, global identifiers
- Computational governance (Chapter 9) — automated policy enforcement, standards
- Data contracts (Chapter 7) — producer-consumer agreements, schema stability

### Data Governance: The Definitive Guide

**Author:** Evren Eryurek, Uri Gilad, Valliappa Lakshmanan, Anita Kibunguchy-Grant, Jessi Ashdown
**Published:** 2021, O'Reilly Media
**ISBN:** 978-1492063490
**Relevance:** Practical governance guidance that complements DAMA DMBOK's theoretical framework. Informs the Governance pillar's approach to classification, PII handling, and lifecycle management.

### Fundamentals of Data Engineering

**Authors:** Joe Reis, Matt Housley
**Published:** 2022, O'Reilly Media
**ISBN:** 978-1098108304
**Relevance:** Practical engineering patterns for data pipelines. Informs the Engineering pillar's checklists on idempotency, CDC, orchestration, and error handling.
**Specific topics referenced:**
- Chapter 5: Data Generation in Source Systems — CDC patterns, event-driven architectures
- Chapter 8: Batch Ingestion Considerations — Idempotency, incremental processing, watermarks
- Chapter 9: Serving Data — Materialised views, data products, access patterns

### Designing Data-Intensive Applications

**Author:** Martin Kleppmann
**Published:** 2017, O'Reilly Media
**ISBN:** 978-1449373320
**Relevance:** Deep technical reference for data system design patterns. Informs understanding of exactly-once semantics, idempotency, event sourcing, and consistency guarantees.
**Specific chapters referenced:**
- Chapter 7: Transactions — Exactly-once semantics, idempotency
- Chapter 11: Stream Processing — Watermarks, event time vs processing time, late data handling
- Chapter 12: The Future of Data Systems — Data integration patterns

### The Data Warehouse Toolkit (3rd Edition)

**Author:** Ralph Kimball, Margy Ross
**Published:** 2013, Wiley
**ISBN:** 978-1118530801
**Relevance:** Definitive reference for dimensional modelling. Informs the Architecture pillar's schema design guidance for star/snowflake schemas, fact tables, dimensions, and slowly changing dimensions.

## Standards and Industry References

### GDPR (General Data Protection Regulation)

**URL:** https://gdpr-info.eu/
**Relevance:** The primary regulatory framework referenced in the Governance pillar. Key articles:
- Article 5: Principles (purpose limitation, data minimisation, accuracy, storage limitation)
- Article 17: Right to erasure (Right to be Forgotten)
- Article 25: Data protection by design and by default
- Article 30: Records of processing activities (lineage relevance)

### CCPA (California Consumer Privacy Act)

**URL:** https://oag.ca.gov/privacy/ccpa
**Relevance:** US data privacy regulation referenced alongside GDPR. Similar requirements for data deletion, disclosure, and purpose limitation.

### Great Expectations

**URL:** https://greatexpectations.io/
**Relevance:** Referenced in the Quality pillar as an example of data quality testing patterns (expectations). Used as an illustration of what automated quality checks look like, not as a required tool.

### dbt (Data Build Tool)

**URL:** https://www.getdbt.com/
**Relevance:** Referenced in the Engineering pillar as an example of declarative pipeline definitions. Used as an illustration of modular, tested, documented transformations, not as a required tool.

### Apache Iceberg / Delta Lake

**URL:** https://iceberg.apache.org/ / https://delta.io/
**Relevance:** Referenced in the Architecture pillar as examples of standardised table formats for interoperability. Used as illustrations, not requirements.

## Domain-Specific Project History

Key PRs that shaped the Data domain specifically:

| PR | What changed | Design impact |
|----|-------------|---------------|
| #5 | Initial Data review system | Established Four Pillars architecture, 4 subagents, prompt structure. Defined "Trusted and Timely" mantra. |
| #12 | Data domain issue | Defined acceptance criteria: 4 parallel subagents, standard severity table format, DAMA DMBOK + Data Mesh frameworks |
| #13 | Summary reports and maturity scoring issue | Defined Data maturity criteria: HYG (no missing PII masking, no breaking schema changes), L1 (schema documented, ownership defined), L2 (freshness SLOs, data contracts), L3 (bitemporality, self-serve discovery) |

For cross-domain PRs (#18, #19, #21, #23), see `../../review-standards/references.md`.

## Attribution Notes

All frameworks in the Data domain are either:
1. **Industry-standard** (DAMA DMBOK quality dimensions, GDPR requirements) — well-attributed
2. **From cited publications** (Data Mesh concepts from Dehghani) — well-attributed
3. **Original to this project** (Four Pillars structure, Decay Patterns taxonomy) — declared as original

No attribution gaps exist for the Data domain at this time.
