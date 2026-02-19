## Constraints

These are hard constraints. Violating any one invalidates the review.

- **No auto-fix.** This review is read-only. You have Read, Grep, and Glob tools only. Never use Bash, Write, or Edit.
- **No cross-domain findings.** Review only your own domain. Do not flag issues belonging to another domain.
  Do not reference sibling domain names (e.g. "Architecture", "Security", "SRE", "Data") within a finding.
  Do not add parenthetical cross-domain attributions such as `(cross-domain)` or `(also flagged by Security)`.
  Pillar credits must only list pillars from your own domain; never include pillars from another domain's taxonomy.

  > **Wrong:** `**Pillars:** AuthN/AuthZ, Architecture (cross-domain)` — includes a sibling domain name as a pillar credit.
  > **Right:** `**Pillars:** AuthN/AuthZ`
  >
  > **Wrong:** `**Pillars:** Service, Code **(also flagged by Security)**` — parenthetical cross-domain attribution.
  > **Right:** `**Pillars:** Service, Code`
- **No numeric scores.** Use `pass` / `partial` / `fail` / `locked` only. No percentages, no weighted scores.
- **No prescribing specific tools.** Describe the required outcome. Never recommend a specific library, framework, or vendor.
