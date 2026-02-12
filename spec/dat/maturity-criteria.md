# Maturity Criteria — Data Domain

> Detailed criteria for each maturity level with defined "sufficient" thresholds. Use this when assessing criteria as Met / Not met / Partially met.

## Hygiene Gate

The Hygiene gate is not a maturity level — it is a promotion gate. Any finding at any level that passes any of the three tests is promoted to `HYG`.

### Test 1: Irreversible

**Question:** If this goes wrong, can the damage be undone?

**Threshold:** If a failure would produce damage that requires more than a re-run or rollback to fix — e.g., silently corrupted data that has already been consumed by downstream systems, deleted records with no backup, PII leaked to an uncontrolled output — this is irreversible.

**Data examples that trigger this test:**
- Pipeline silently drops records on schema mismatch with no error or dead-letter queue — consumers believe the data is complete, but records are missing
- `pd.to_numeric(df['amount'], errors='coerce')` — invalid values silently become NaN, aggregate metrics are wrong, and nobody knows
- Migration script with unbounded `DELETE` or `TRUNCATE` without a backup step
- Fan-out join that inflates a financial metric — business decisions made on inflated numbers before anyone notices
- Background job that purges records before confirming downstream receipt

**Data examples that do NOT trigger this test:**
- Missing schema documentation (bad practice but reversible — documentation can be added)
- Inefficient query (costs money but doesn't corrupt data)
- Naming convention violation (style issue, no data impact)

### Test 2: Total

**Question:** Can this take down the entire service or cascade beyond its boundary?

**Threshold:** If a failure can exhaust shared resources (warehouse compute, storage, network) to the point where other workloads are affected, or if the failure propagates corruption to other data products beyond the producer's boundary, this is total.

**Data examples that trigger this test:**
- Unbounded `SELECT *` in a shared data warehouse that consumes all available compute slots, blocking other teams' queries
- Deadly diamond that corrupts a shared dimension table used by all downstream analytics
- Schema change on a high-fan-out table (many consumers) without versioning — all consumers break simultaneously
- Pipeline with no circuit breaker that retries a failing source indefinitely, consuming rate limit budget for all users

**Data examples that do NOT trigger this test:**
- A single pipeline fails and produces no output (localised failure, consumers see stale data but not corrupt data)
- A query is slow but doesn't block other users (performance issue, not total failure)

### Test 3: Regulated

**Question:** Does this violate a legal or compliance obligation?

**Threshold:** If the code would cause a breach of data protection law (GDPR, CCPA, HIPAA), financial regulation, or other legal obligations, this is regulated.

**Data examples that trigger this test:**
- PII (emails, phone numbers, SSN, health data) written to application logs without masking
- Raw PII exported to an analytics layer without pseudonymisation or access controls
- No mechanism for Right-to-be-Forgotten (GDPR Article 17) when processing EU citizen data
- Health data stored without encryption at rest (HIPAA violation)
- Financial data used for purposes beyond the original consent (purpose limitation violation)

**Data examples that do NOT trigger this test:**
- Internal aggregate metrics without PII (no personal data involved)
- Missing data classification labels on non-sensitive data (good practice but not a legal violation)
- Ownership metadata missing (governance gap, not a compliance violation unless regulated data is involved)

---

## Level 1 — Foundations

**Overall intent:** The basics are in place. The data can be understood, used, and maintained. A new team member can work with this data without relying on tribal knowledge.

### Criterion 1.1: Schemas are documented with field-level descriptions

**Definition:** Every table, view, or data model has documentation that describes what it contains, and fields have individual descriptions explaining their business meaning.

**Met (sufficient):**
- Table/model has a description (purpose, source, grain)
- Fields have descriptions that explain business meaning, not just technical type
- Descriptions use terminology that a consumer (not just the producer) can understand
- At minimum: all fields in published/external-facing tables are described

**Partially met:**
- Table has a description but fields don't, or only some fields are described
- Descriptions exist but are auto-generated placeholders ("column_1 description")
- Descriptions exist but use producer-internal jargon that consumers can't understand

**Not met:**
- No descriptions on tables or fields
- Descriptions exist only in external documentation that is not co-located with the schema
- Schema is completely undocumented — understanding requires reading pipeline code

### Criterion 1.2: Each data asset has a defined owner

**Definition:** Every table, pipeline, or data product has a clearly identified owner — both a business owner (accountable for data value and rules) and a technical owner (accountable for quality and operations).

**Met (sufficient):**
- Owner is declared in metadata, schema comments, catalog, or configuration
- Both business and technical ownership are identifiable (may be the same team for small orgs)
- Owner information is findable without asking someone (discoverable from the data asset itself)

**Partially met:**
- Technical owner identifiable (from git blame, pipeline config) but no business owner
- Owner documented in an external system (wiki, spreadsheet) but not in the data asset's metadata
- Some assets have owners, others don't

**Not met:**
- No owner information anywhere
- Ownership can only be determined by asking around ("Who owns this table?")

### Criterion 1.3: Input data is validated

**Definition:** Data entering the pipeline is checked for type correctness, constraint adherence, and referential integrity before it is processed and served to consumers.

**Met (sufficient):**
- Input data types are enforced (not silently coerced)
- Required fields are checked for NULL
- Primary key uniqueness is enforced
- At minimum: validation exists on the first ingestion boundary (where external data enters the system)
- Validation failures are visible (logged, alerted, or routed to a dead-letter queue) — not silently dropped

**Partially met:**
- Some validation exists but doesn't cover all fields or all ingestion points
- Validation exists but failures are silently swallowed (logged at DEBUG with no alerting)
- Type checking exists but referential integrity is not validated

**Not met:**
- No validation on inbound data
- Validation exists but silently coerces invalid data (e.g., `errors='coerce'`) with no logging
- Schema mismatches cause silent record drops

### Criterion 1.4: Processing is idempotent

**Definition:** Re-running a pipeline with the same input produces the exact same output. No duplicates, no missing records, no side effects from multiple executions.

**Met (sufficient):**
- Write strategy is inherently idempotent: MERGE/UPSERT, DELETE-INSERT by partition, or INSERT with conflict resolution
- Non-deterministic functions (`NOW()`, `RANDOM()`, `UUID()`) are either avoided or seeded/pinned
- Processing does not depend on execution order when parallelised
- Re-running after a failure does not produce duplicates

**Partially met:**
- Write strategy is mostly idempotent but some paths use bare INSERT (append-only without deduplication)
- Non-deterministic functions are used but the impact is limited (e.g., `loaded_at` timestamp differs but data is otherwise identical)
- Idempotency works for normal runs but edge cases (partial failure mid-write) can produce duplicates

**Not met:**
- Bare INSERT with no deduplication — re-runs always produce duplicates
- Pipeline depends on `NOW()` for business logic (different result on each run)
- No mechanism to handle partial failure (interrupted write leaves partial data)

---

## Level 2 — Hardening

**Overall intent:** Production-ready practices. The data can be trusted and monitored. Teams can set and track quality targets. Consumers have confidence in the data.

**Prerequisite:** All L1 criteria must be met.

### Criterion 2.1: Freshness expectations are defined and monitored

**Definition:** There are explicit expectations for when data should be available, and the system can detect when those expectations are not met.

**Met (sufficient):**
- Freshness SLO is defined (documented or in configuration) — e.g., "available within 15 minutes of event", "daily snapshot by 6am UTC"
- Processing latency (gap between event time and data availability) is measurable from the data itself (`loaded_at` timestamps, watermarks)
- There is a mechanism to detect when freshness degrades (alert, monitoring check, or automated test)

**Partially met:**
- Freshness expectation exists informally ("we expect it by morning") but is not documented or measured
- `loaded_at` timestamps exist but no automated check compares them against a target
- Monitoring exists but the SLO threshold is not defined (alert fires on "no data" but not on "late data")

**Not met:**
- No freshness expectation defined
- No way to tell when data was last updated (no `loaded_at`, no watermark, no processing timestamp)
- Consumers discover staleness by noticing wrong results, not from monitoring

### Criterion 2.2: Contracts exist between producers and consumers

**Definition:** Published data products have a formal or semi-formal agreement about what the consumer can expect: schema stability, quality guarantees, and change management process.

**Met (sufficient):**
- Schema is versioned or has a stability guarantee (consumers know which fields are stable)
- Breaking changes have a defined process: notification, deprecation period, migration support
- Quality expectations are documented: what validation is applied, what completeness guarantees exist
- At minimum: a YAML/JSON contract file, schema documentation with stability labels, or explicit API versioning

**Partially met:**
- Schema is documented but there's no process for managing breaking changes
- Contract exists but only covers schema, not quality or freshness expectations
- Breaking changes are communicated ad hoc (Slack message) rather than through a defined process

**Not met:**
- No contract — consumers discover changes by breakage
- Breaking changes deployed without notification
- No distinction between internal (can change anytime) and published (stable) interfaces

### Criterion 2.3: Data can be traced from source to destination

**Definition:** For any data product, the lineage is clear: where did the data come from, what transformations were applied, and where does it go?

**Met (sufficient):**
- Source systems are identified for each data product
- Transformations are documented or self-documenting (declarative pipeline definitions, SQL with clear source references)
- Impact analysis is possible: "if source X changes, what downstream products are affected?"
- Lineage is captured automatically (from pipeline metadata, DAG definitions) or maintained alongside the code

**Partially met:**
- Source is known but intermediate transformations are opaque (complex SQL without documentation)
- Lineage exists for some pipelines but not all
- Lineage is documented but not maintained (outdated)

**Not met:**
- No lineage information — "where does this data come from?" requires code archaeology
- Derived tables reference source names that don't map to any known system
- Transformations are undocumented and pipeline logic is opaque

### Criterion 2.4: Quality is monitored with automated checks

**Definition:** Data quality is verified through automated checks that run as part of the pipeline, not just during development.

**Met (sufficient):**
- Automated checks exist for at minimum: row count expectations, NULL rates on required fields, uniqueness on primary keys
- Checks run in production (part of the pipeline or a scheduled validation job)
- Check failures are visible (alerts, pipeline failure, dashboard)
- Checks cover both structural quality (schema conformance) and content quality (value ranges, distributions)

**Partially met:**
- Some automated checks exist but coverage is spotty (only row counts, no content checks)
- Checks exist in development/CI but not in production
- Checks run but failures are only logged (no alerting, no pipeline halt)

**Not met:**
- No automated data quality checks
- Quality issues discovered by consumers ("these numbers look wrong")
- Checks exist only as manual spot-checks

### Criterion 2.5: Source and target are reconciled

**Definition:** There is a verification mechanism that compares source data with the target to confirm that the pipeline hasn't introduced errors, lost records, or created duplicates.

**Met (sufficient):**
- At least one reconciliation mechanism exists: row count comparison, sum verification, or checksum matching
- Reconciliation runs automatically (part of the pipeline or scheduled)
- Discrepancies trigger a visible signal (alert, log, or pipeline failure)

**Partially met:**
- Reconciliation exists but is manual (someone runs a query periodically)
- Row count check exists but no content-level verification (could have right count but wrong data)
- Reconciliation runs but discrepancies are only logged (no alert)

**Not met:**
- No reconciliation between source and target
- The pipeline is assumed correct if it doesn't error
- Discrepancies are discovered by consumers

---

## Level 3 — Excellence

**Overall intent:** Best-in-class. The data products are a model for others. Data management is a first-class engineering discipline.

**Prerequisite:** All L2 criteria must be met.

### Criterion 3.1: Temporal changes are tracked for audit-critical data

**Definition:** For data where historical accuracy matters (financial, regulatory, compliance), the system tracks both when data changed in reality and when it was recorded.

**Met (sufficient):**
- Bitemporality is implemented for audit-critical tables: transaction time (system recorded) and valid time (reality)
- Late-arriving data and corrections are handled without overwriting history
- Point-in-time queries are possible ("what did we know about this customer as of last Tuesday?")

**Partially met:**
- Transaction time is tracked (audit log of changes) but valid time is not
- History is preserved but point-in-time queries are not straightforward (requires complex joins)
- Bitemporality is implemented for some audit-critical tables but not all

**Not met:**
- No temporal tracking — current state only (UPDATE in place)
- Changes overwrite previous values with no history
- Late-arriving data causes retroactive changes to historical reports

### Criterion 3.2: Data assets are discoverable without tribal knowledge

**Definition:** A person or system can find, understand, and evaluate a data product without asking the producer directly.

**Met (sufficient):**
- Data products are registered in a catalog or discovery mechanism
- Each product has: description, owner, freshness information, quality indicators, sample data or preview
- Search and filtering works (by domain, by tag, by owner)
- Documentation is sufficient for self-service consumption

**Partially met:**
- Catalog exists but is incomplete (not all products registered)
- Products are listed but metadata is sparse (name only, no description or quality info)
- Discovery requires knowledge of the catalog's existence (not linked from the data itself)

**Not met:**
- No catalog or discovery mechanism
- Finding data requires asking someone or browsing file systems
- Data products are only known through word of mouth

### Criterion 3.3: Reconciliation runs automatically with alerting on divergence

**Definition:** Source-to-target reconciliation is fully automated and produces alerts when discrepancies exceed thresholds.

**Met (sufficient):**
- Reconciliation runs automatically as part of the pipeline or on a schedule
- Thresholds are defined for acceptable divergence (not just zero-tolerance)
- Alerts fire when thresholds are exceeded
- Alert includes context: which records diverge, by how much, since when

**Partially met:**
- Reconciliation is automated but alerting is not configured
- Alerting exists but thresholds are too sensitive (alert fatigue) or too loose (real issues missed)
- Automated for some pipelines but not all critical ones

**Not met:**
- Reconciliation is manual
- No divergence detection
- Discrepancies discovered by consumers or during audits
