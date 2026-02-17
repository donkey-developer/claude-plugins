---
name: security
description: Security code review across AuthN/AuthZ, Data Protection, Input Validation, and Audit/Resilience.
argument-hint: [path|PR#|.]
allowed-tools: Task, Read, Grep, Glob, Bash, Write
---

## Synthesis

**Pre-filter:** Before applying the shared synthesis algorithm, remove any finding with confidence below 50%.
Only HIGH (>80%) and MEDIUM (50-80%) confidence findings proceed to deduplication.
