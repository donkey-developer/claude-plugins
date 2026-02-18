# Governance

Is the data managed right?

The Governance pillar evaluates whether the data is managed with appropriate controls for compliance, privacy, lifecycle, ownership, and lineage.
It focuses on evidence of governance in the code itself — not on the existence of external policies.
When this pillar is weak, regulated data is exposed, personal data cannot be deleted on request, and nobody knows who is accountable for data that goes wrong.

**Look for evidence in code:** Governance assessment focuses on code evidence — TTL columns, partition expiration, soft-delete flags, PII masking at ingestion, access controls in DDL, lineage declarations.
Do not expect policy documents; assess what the code enforces.

## Focus Areas

The Governance pillar applies the duality through two specific lenses.

### Decay Pattern focus (how the data is going wrong)

- **Compliance drift** — Governance owns regulatory compliance.
  PII exposure, missing retention policies, and absent lifecycle management create legal and reputational risk.
  Look for: raw PII in analytics or logs, no retention mechanism, no Right-to-be-Forgotten path, missing data classification.
- **Ownership erosion** — Governance owns accountability.
  Without clear business and technical owners, data becomes orphaned.
  Look for: no owner metadata on tables, no lineage documentation, no catalog registration.

### Quality Dimension focus (what should protect against failure)

- **Completeness** — Governance verifies that required metadata is present: classification, ownership, retention policy, lineage.
- **Accuracy** — Governance verifies that lineage is correct — data can be traced from source to destination through all transformations.

## Anti-Pattern Catalogue

### GP-01: PII in analytics without masking

Raw email addresses, phone numbers, or SSNs written to analytics tables, data lakes, or exported files without hashing, tokenisation, or redaction.

**Why it matters:** Analytics layers typically have broader access controls.
PII is now accessible to anyone with analytics access.
Violates data minimisation and purpose limitation principles.
Decay Pattern: Compliance drift (Regulated — GDPR/CCPA violation).
Typical severity: HIGH / HYG (Regulated — PII exposure with broad access).

### GP-02: PII in logs

PII (email, SSN, health data) interpolated into log messages, debug tables, or error output.

**Why it matters:** Logs are aggregated, retained, and often have broad access.
PII cannot be selectively removed from log aggregation systems.
The PII persists in log history even if the code is fixed.
Decay Pattern: Compliance drift (Regulated + Irreversible — cannot unlog from aggregated stores).
Typical severity: HIGH / HYG (Regulated + Irreversible).

### GP-03: No retention policy

Tables with no partition scheme for lifecycle management, no TTL, no scheduled purge job.
Table grows forever.

**Why it matters:** Storage costs grow linearly.
If the table contains PII, there's no mechanism for GDPR deletion or retention compliance.
Query performance degrades as the table grows.
Decay Pattern: Compliance drift (Completeness — lifecycle metadata missing).
Typical severity: MEDIUM / L2.
Escalates to HYG if the table contains regulated data (Regulated).

### GP-04: No ownership metadata

A table with no documented owner — no comments, no catalog entry, no contact information.

**Why it matters:** When something goes wrong, nobody knows who to call.
When the data needs updating, nobody takes responsibility.
The data becomes an orphan that deteriorates over time.
Decay Pattern: Ownership erosion (Completeness — owner metadata missing).
Typical severity: MEDIUM / L1.

### GP-05: No lineage tracking

Derived tables that reference source tables with no documentation of the transformation chain.
`CREATE TABLE derived AS SELECT ... FROM source` — which source system? What upstream transformations?

**Why it matters:** Impact analysis is impossible.
Root cause analysis requires code archaeology.
When the source changes, nobody knows what's affected.
Decay Pattern: Ownership erosion (Accuracy — lineage correctness unverifiable).
Typical severity: MEDIUM / L2.

### GP-06: No Right-to-be-Forgotten mechanism

System processes EU citizen data but has no mechanism to identify and remove a specific user's data across all tables and downstream systems.

**Why it matters:** GDPR Article 17 requires the ability to delete personal data on request.
Without a mechanism, the organisation cannot comply, risking fines of up to 4% of global revenue.
Decay Pattern: Compliance drift (Regulated — GDPR non-compliance).
Typical severity: HIGH / HYG (Regulated).

### GP-07: Missing data classification

A table containing sensitive data (customer records, financial transactions, health data) with no classification label indicating its sensitivity level.

**Why it matters:** Without classification, access controls can't be calibrated.
Teams don't know what controls to apply.
Sensitive data may be copied to less-protected environments.
Decay Pattern: Compliance drift (Completeness — classification metadata missing).
Typical severity: MEDIUM / L1.
Escalates to HIGH if the data is clearly PII or regulated.

### GP-08: Unmasked PII in non-production environments

Production data copied to development or staging environments without masking PII.

**Why it matters:** Non-production environments typically have weaker access controls.
Developers and testers gain access to real customer data.
Violates data minimisation principles.
Decay Pattern: Compliance drift (Regulated — PII in uncontrolled environment).
Typical severity: HIGH / HYG (Regulated — PII with wider access than necessary).

## Review Checklist

When assessing the Governance pillar, work through each item in order.

1. **PII identification and classification** — Does the code handle PII (emails, phone numbers, SSNs, health data, financial data)?
   If this data were leaked, what would the impact be?
   Is PII masked, hashed, or tokenised before it reaches analytics layers or logs?
   Is there a data classification label on tables containing sensitive data?

2. **Right-to-be-Forgotten** — If the code processes EU citizen data, is there a mechanism to identify and delete a specific user's data on request?
   Can a deletion request be actioned across all tables and downstream systems?
   Is crypto-shredding used as an alternative where direct deletion is impractical?

3. **Retention and lifecycle** — Does the table have a retention policy?
   Is there a partition scheme, TTL, or scheduled purge job that prevents unbounded growth?
   If the table contains PII, is the retention period aligned with legal requirements?

4. **Ownership** — Who is accountable for this data?
   Is the owner declared in metadata, schema comments, or catalog registration?
   Both business and technical ownership should be identifiable without asking someone.

5. **Lineage** — Can we trace this data back to its original source?
   Are source systems identified for each data product?
   Are transformations documented or self-documenting (declarative pipeline definitions, clear SQL source references)?
   If this source changes, what downstream products are affected?

6. **Non-production data handling** — Does the code copy production data to non-production environments?
   Is PII masked before it reaches development or staging environments?

## Severity Framing

Severity for Governance findings is about **regulatory and accountability consequence** — the legal, reputational, and operational risk if the code ships as-is.

- **PII exposure** — Is regulated personal data accessible to parties who shouldn't have it?
  Raw PII in analytics or logs is always HYG (Regulated).
  Pseudonymised data with reversible hashing is HIGH, not HYG.
- **Compliance violations** — Does the code violate GDPR, CCPA, HIPAA, or other applicable regulations?
  Missing Right-to-be-Forgotten mechanism for GDPR-covered data is HYG.
  Missing data classification on non-sensitive internal data is MEDIUM / L1.
- **Ownership and lineage** — Can accountability and impact be traced?
  No owner on a critical production table is MEDIUM / L1.
  No lineage on a complex derived table is MEDIUM / L2.
  No lineage feeding external reports is HIGH / L2.
