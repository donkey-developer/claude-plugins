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
| Criterion name | ✅ Pass | ⚠️ Partial<br>• reason one<br>• reason two | 🔒 Locked |

Rules:
- Use emoji + label for every cell: ✅ Pass · ⚠️ Partial · ❌ Failure · 🔒 Locked
- Place commentary on a new line using `<br>` and `•` bullets — one bullet per distinct reason; no semi-colon lists
- If the pillar has any HYG-severity finding, set L1 = ❌ Failure and L2/L3 = 🔒 Locked regardless of criteria assessment
- Mark a level 🔒 Locked when the prior level is not ✅ Pass
