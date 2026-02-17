---
name: all
description: Comprehensive code review across all domains — dispatches 16 agents in parallel.
argument-hint: [path|PR#|.]
allowed-tools: Task, Read, Grep, Glob, Bash, Write
---

## Synthesis

No domain-specific synthesis rules apply for Architecture.
The shared synthesis algorithm applies as-is.

## Synthesis

Data applies a scope filter: focus on SQL, dbt, Spark, and pipeline configurations.
Apply consumer-first perspective — evaluate every change from the downstream consumer's point of view.
The shared synthesis algorithm applies as-is.
