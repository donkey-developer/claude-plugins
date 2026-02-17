## Governance Pillar — Is the Data Managed Right?

The Governance pillar examines compliance, classification, ownership, and lifecycle management.
It evaluates whether data is properly identified, protected, and traceable throughout its lifecycle.
The central question is: if a regulator or auditor asks who owns this data, where it came from, and when it will be deleted, can you answer?

## Focus Areas

- **Compliance analysis** — PII is identified, masked, and subject to purpose limitation.
  Flag raw email, phone, or SSN values written to analytics tables, logs, or non-production environments without hashing, tokenisation, or redaction.
- **Lifecycle management** — retention policies, TTL, and scheduled purges are defined.
  Flag tables with no partition scheme for lifecycle management, no TTL, and no scheduled purge job.
- **Ownership and accountability** — every table has a documented owner and classification label.
  Flag tables with no owner metadata in comments, catalogue entries, or configuration.
- **Lineage and traceability** — transformation chains are documented from source to destination.
  Flag derived tables with no documented upstream sources or transformation logic.
- **Access controls** — data classification determines the required level of protection.
  Flag sensitive data with no classification label, and classified data with no corresponding access restrictions.
- **Right-to-deletion** — GDPR Article 17 compliance mechanisms exist for personal data.
  Flag systems that process EU citizen data with no mechanism to identify and remove a specific user's records.

## Anti-Patterns

### GP-01: PII in analytics without masking

Raw email addresses, phone numbers, or SSNs written to analytics tables without hashing, tokenisation, or redaction.
Analytics layers typically have broader access controls, exposing PII to anyone with query access.

```sql
INSERT INTO analytics.user_activity (user_id, email, page_views)
SELECT user_id, email, COUNT(*)  -- raw email exposed to all analytics consumers
FROM events GROUP BY user_id, email;
```

**Decay Pattern:** Compliance drift | **Quality Dimension:** Regulated | **Severity:** HIGH / HYG

### GP-02: PII in logs

PII interpolated into log messages, debug tables, or error output.
Logs are aggregated, broadly accessible, and retained indefinitely; PII cannot be selectively removed from log stores.

```python
logger.info(f"Processing record for {user.email}, SSN: {user.ssn}")  # PII persists in log history
```

**Decay Pattern:** Compliance drift | **Quality Dimension:** Regulated | **Severity:** HIGH / HYG (Irreversible)

### GP-03: No retention policy

Tables with no partition scheme for lifecycle management, no TTL, and no scheduled purge.
Storage grows without bound; if the table contains PII, there is no mechanism for GDPR retention compliance.

**Decay Pattern:** Compliance drift | **Quality Dimension:** Completeness | **Severity:** MEDIUM / L2

### GP-04: No ownership metadata

A table with no documented owner — no comments, no catalogue entry, no contact information.
When something breaks, nobody knows who to call; the data becomes an orphan that deteriorates over time.

**Decay Pattern:** Ownership erosion | **Quality Dimension:** Completeness | **Severity:** MEDIUM / L1

### GP-05: No lineage tracking

Derived tables with no documented transformation chain from source to target.
Impact analysis is impossible; root cause investigation requires code archaeology across multiple repositories.

**Decay Pattern:** Ownership erosion | **Quality Dimension:** Accuracy | **Severity:** MEDIUM / L2

### GP-06: No Right-to-be-Forgotten mechanism

EU citizen data processed with no mechanism to identify and delete a specific user's records across all tables and downstream systems.
GDPR Article 17 non-compliance risks fines of up to 4% of global revenue.

**Decay Pattern:** Compliance drift | **Quality Dimension:** Regulated | **Severity:** HIGH / HYG

### GP-07: Missing data classification

Sensitive data (customer records, financial transactions, health data) with no classification label indicating its sensitivity level.
Without classification, access controls cannot be calibrated and data may be copied to less-protected environments.

**Decay Pattern:** Compliance drift | **Quality Dimension:** Completeness | **Severity:** MEDIUM / L1

### GP-08: Unmasked PII in non-production environments

Production data copied to development or staging environments without masking PII.
Non-production environments typically have weaker access controls, giving developers and testers access to real customer data.

```sql
-- Production data copied directly to dev without masking
CREATE TABLE dev.customers AS SELECT * FROM prod.customers;  -- real PII now in dev
```

**Decay Pattern:** Compliance drift | **Quality Dimension:** Regulated | **Severity:** HIGH / HYG

## Checklist

- [ ] Is PII identified, and is it masked or tokenised before reaching analytics, logs, or exports?
- [ ] Does every table containing personal data have a documented retention policy?
- [ ] Can the organisation delete a specific user's data across all systems on request (Right-to-be-Forgotten)?
- [ ] Is there a data classification label for every table containing sensitive or regulated data?
- [ ] Does every table have a documented owner who is accountable for its accuracy and lifecycle?
- [ ] Are transformation chains documented so that lineage from source to target is traceable?
- [ ] Are non-production environments free of unmasked production PII?
- [ ] Do access controls reflect the data classification level (e.g., restricted data requires elevated permissions)?
- [ ] Are PII fields excluded from log messages, debug tables, and error output?
- [ ] Is there a scheduled process to enforce retention policies (TTL, partition drops, purge jobs)?

## Positive Indicators

- PII is hashed, tokenised, or redacted before reaching analytics or export layers.
- Every table has a documented owner, classification label, and retention policy.
- Lineage is tracked and queryable from source through to consumer-facing tables.
- Right-to-be-Forgotten requests can be fulfilled across all systems within the required timeframe.
- Non-production environments use synthetic or masked data, never raw production PII.
- Log messages reference opaque identifiers, not raw PII.
- Data classification drives access control policy automatically.
