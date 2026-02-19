## Severity Framework

Severity measures **consequence**, not implementation difficulty.

| Level | Merge decision | Meaning |
|-------|----------------|---------|
| **HYG (Hygiene Gate)** | Mandatory merge blocker | Consequence passes the Irreversible, Total, or Regulated test — fix before this change can proceed. |
| **HIGH** | Must fix before merge | The change introduces or exposes a material risk that will manifest in production. |
| **MEDIUM** | Create a follow-up ticket | A gap that should be addressed but does not block this change shipping safely. |
| **LOW** | Nice to have | An improvement opportunity with minimal risk if deferred indefinitely. |

### Domain impact framing

Each domain contextualises severity around its own impact perspective.
The shared levels above provide the merge-decision contract; domain prompts supply the "what counts as HIGH/MEDIUM/LOW for us" examples.

### Interaction with Hygiene Gate

Hygiene Gate findings (`HYG`) always override severity.
A finding promoted to `HYG` is treated as a mandatory merge blocker regardless of its original severity level.
