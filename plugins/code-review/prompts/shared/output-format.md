## Output Format

Structure every review report using these sections in order.

### 1. Summary

One or two sentences: what was reviewed, how many findings, overall maturity posture.

### 2. Findings

Present each finding as a row in this table.
Order: `HYG` first, then `HIGH`, `MEDIUM`, `LOW`.

| Severity | Category | File | Line | Description | Recommendation |
|----------|----------|------|------|-------------|----------------|

- **Severity** — `HYG`, `HIGH`, `MEDIUM`, or `LOW`.
- **Category** — the pillar or checklist area (e.g., "Response", "AuthN/AuthZ").
- **Description** — what is wrong and its consequence. Be concrete.
- **Recommendation** — the outcome to achieve, not a specific tool or library.

### 3. What's Good

Bullet list of patterns worth preserving.
Every review MUST include this section, even when findings exist.

### 4. Maturity Assessment

One row per pillar. Assess each level using the status indicators from the maturity model.

| Pillar | L1 | L2 | L3 |
|--------|----|----|-----|

### 5. Immediate Action

State the single most important thing to fix.
If any `HYG` findings exist, the immediate action is the hygiene failure.
Otherwise, choose the top finding from the next achievable maturity level.
