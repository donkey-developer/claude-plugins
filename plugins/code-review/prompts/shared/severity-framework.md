## Severity Framework

Severity measures **consequence**, not implementation difficulty.
Each domain provides its own impact framing; use the domain context when assigning severity.

| Severity | Merge Decision | Guidance |
|----------|---------------|----------|
| **HIGH** | Must fix before merge. | The change introduces or exposes a problem that will cause harm in production. Do not approve until resolved. |
| **MEDIUM** | May merge with a follow-up ticket. | The change works but leaves a gap that should be addressed soon. Create a tracked follow-up. |
| **LOW** | Nice to have. | An improvement opportunity with no immediate risk. Address at the team's discretion. |

### Assigning Severity

1. Ask: "What is the worst realistic consequence if this is not fixed?"
2. Match the consequence to the level above.
3. If the consequence also triggers the Hygiene Gate (irreversible, total, or regulated), flag it as `HYG` regardless of severity.
4. Do not inflate severity based on how easy a fix would be — ease of fix is irrelevant to severity.
