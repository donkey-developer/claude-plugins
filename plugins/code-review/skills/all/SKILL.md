---
name: all
description: Comprehensive code review across all domains — dispatches 16 agents in parallel.
argument-hint: [path|PR#|.]
allowed-tools: Task, Read, Grep, Glob, Bash, Write
---

## Synthesis Algorithm

Combine findings from all pillar subagents into a single domain report.

### Step 1: Collect

Gather all findings from every subagent. Preserve the original severity, maturity level, category, and recommendation.

### Step 2: Domain Pre-filters

Apply domain-specific filters before deduplication:

- **Security:** Remove findings with confidence below 50%. Every finding must include an exploit path.
- **Data:** Restrict scope to SQL, dbt, Spark, and pipeline configuration files. Apply consumer-first perspective.
- **SRE, Architecture:** No domain-specific pre-filter. Proceed directly to deduplication.

### Step 3: Deduplicate

When two or more agents flag the same `file:line`, merge into one finding:

- Take the **highest severity** (HYG > HIGH > MEDIUM > LOW)
- Take the **most restrictive maturity level** (HYG > L1 > L2 > L3)
- Combine recommendations from all contributing agents
- Credit all contributing subagents in the Category column

### Step 4: Aggregate Maturity

Merge per-criterion assessments from all subagents into one maturity table:
- All criteria met at a level = `pass`
- Mix of met and not met = `partial`
- All criteria not met or critical criteria missing = `fail`
- Previous level not passed = `locked`

### Step 5: Prioritise

Order the final findings list:

1. `HYG` findings first
2. Then by severity: `HIGH` > `MEDIUM` > `LOW`
3. Within the same severity, order by file path

## Synthesis Pre-filter

**Apply before deduplication.**

Remove any finding with confidence below 50% (LOW confidence).
These are theoretical concerns that add noise without value.

After removing LOW confidence findings, continue with the shared synthesis algorithm: deduplicate, aggregate, and prioritise.

Domain-specific synthesis rule: the confidence filter runs **before** deduplication.
A finding removed by the confidence filter does not appear in the synthesised output, even if multiple pillars raised the same low-confidence concern.

## Synthesis

### Data Pre-filter

Before deduplication, apply the following domain-specific filters:

**Scope filter:** Focus analysis on data-related files — SQL files, Python/Spark data processing scripts, dbt models, pipeline definitions, schema files, and migration scripts.
Non-data files (application code, UI components, configuration unrelated to data) should receive lower analytical weight; flag findings only where data handling is directly implicated.

**Consumer-first perspective:** For every finding, ask "How will downstream consumers experience this?"
A schema change that the producer considers minor may be a breaking change for consumers.
Prioritise findings that affect data consumers over findings that only affect internal implementation.
