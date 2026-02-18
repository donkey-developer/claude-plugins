## Output Format

Structure every review with these four sections in order.

### Summary

One to two sentences: what was reviewed, the dominant risk theme, and the overall maturity posture.

### Findings

Present findings in a single table, ordered by priority: `HYG` first, then `HIGH` > `MEDIUM` > `LOW`.

| Location | Severity | Category | Finding | Recommendation |
|----------|----------|----------|---------|----------------|
| `file:line` | HYG / HIGH / MEDIUM / LOW | Domain or pillar | What is wrong and why it matters | Concrete next step |

If there are no findings, state "No findings" and omit the table.

### What's Good

List patterns worth preserving.
This section is **mandatory** — every review must include it.

### Maturity Assessment

| Criterion | L1 | L2 | L3 |
|-----------|----|----|-----|
| Criterion name | `pass` / `partial` / `fail` | `pass` / `partial` / `fail` / `locked` | `pass` / `partial` / `fail` / `locked` |

Mark a level `locked` when the prior level is not `pass`.
