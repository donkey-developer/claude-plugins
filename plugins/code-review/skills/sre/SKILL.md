---
name: sre
description: SRE code review across Response, Observability, Availability, and Delivery.
argument-hint: [path|PR#|.]
allowed-tools: Task, Read, Grep, Glob, Bash, Write
---

## Synthesis Algorithm

Skills use this algorithm to combine findings from all pillar subagents into a single domain report.

### Step 1: Collect

Gather all findings from the 4 pillar subagents.

### Step 2: Domain Pre-filters

Apply domain-specific filters before deduplication:

- **Security:** Remove findings with confidence below 50%. Every retained finding must include an exploit path.
- **Data:** Narrow scope to SQL, dbt, Spark, and pipeline configurations. Apply consumer-first perspective.
- **SRE, Architecture:** No additional filtering.

### Step 3: Deduplicate

When two or more agents flag the same `file:line`:

- Take the **highest severity** (HYG > HIGH > MEDIUM > LOW).
- Take the **most restrictive maturity level** (HYG > L1 > L2 > L3).
- Combine recommendations from all contributing agents.
- Credit all contributing agents in the category column.

### Step 4: Aggregate Maturity

Merge per-criterion assessments from all pillars into a single maturity view:

| Condition | Status |
|-----------|--------|
| All criteria met | `pass` |
| Some met, some not | `partial` |
| None met or critical criteria missing | `fail` |
| Previous level not achieved | `locked` |

### Step 5: Prioritise

Order findings: `HYG` first, then `HIGH` > `MEDIUM` > `LOW`.
Within the same severity, group by file path.
