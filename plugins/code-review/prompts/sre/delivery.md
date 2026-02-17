## Delivery Pillar

**Mandate:** Can changes be deployed and rolled back safely?

Reviews deployment safety, migration reversibility, and configuration management.
If a deployment goes wrong, the team should be one command away from recovery, not one backup restore away.

### Focus Areas

- Database migrations are reversible without data loss or downtime.
- API changes are backward-compatible or versioned.
- Configuration changes do not require coordinated multi-service deployments.
- Feature flags gate new functionality until it is stabilised.
- Deployments proceed without planned downtime.
- Secrets are never committed to source control.

### SEEMS/FaCTOR Emphasis

| SEEMS focus | FaCTOR defence |
|-------------|----------------|
| Misconfiguration | Output correctness |
| Shared fate | Fault isolation |
| Misconfiguration | Availability |

---

## Anti-Patterns

### DP-01: Non-reversible database migration

```sql
ALTER TABLE orders DROP COLUMN legacy_status;
DROP TABLE audit_log;
ALTER TABLE users RENAME COLUMN name TO full_name;
```

Old code expects the dropped or renamed schema; rollback requires a backup restore, which means downtime.
The deploy is a one-way door.

**SEEMS:** Misconfiguration | **FaCTOR:** Output correctness | **Typical:** HIGH / HYG (Irreversible)

### DP-02: Breaking API change without versioning

Removing or renaming a field, changing a response shape, or altering endpoint paths without a versioned migration path.
During rolling deploys some clients hit old instances and some hit new, causing intermittent failures.

**SEEMS:** Shared fate | **FaCTOR:** Output correctness | **Typical:** HIGH / L1

### DP-03: Config change requires coordinated deployment

A configuration value in one service only works if another service is deployed at the same time with a matching change.
Coordinated deploys are fragile; if one succeeds and the other fails, the system is left in an inconsistent state.

**SEEMS:** Shared fate | **FaCTOR:** Fault isolation | **Typical:** MEDIUM / L2

### DP-04: Removing feature flag before stabilisation

New functionality is merged without a feature flag, or the flag is removed before the feature has run in production long enough to confirm stability.
The only remediation is a full code rollback; with a flag, the team could disable the feature in seconds.

**SEEMS:** Misconfiguration | **FaCTOR:** Availability | **Typical:** MEDIUM / L2

### DP-05: Deployment requires downtime

The deployment process requires taking the service offline — maintenance windows, stop-deploy-start sequences, or incompatible schema changes that prevent old and new code from coexisting.
Every deployment is a planned outage, constraining deploy frequency and delaying hotfixes.

**SEEMS:** Shared fate | **FaCTOR:** Availability | **Typical:** MEDIUM / L3

### DP-06: Missing health check for new functionality

New functionality introduces a dependency (database table, external API, message queue) but the health check is not updated to verify it.
The service reports healthy even when the new feature's dependencies are down; traffic is routed to instances that cannot serve requests.

**SEEMS:** Misconfiguration | **FaCTOR:** Availability | **Typical:** MEDIUM / L1

### DP-07: Hardcoded values that should be configurable

```python
timeout = 30
MAX_CONNECTIONS = 10
```

Changing operational parameters requires a code change and a full deployment cycle.
Values cannot be adjusted during incidents when rapid tuning is needed most.

**SEEMS:** Misconfiguration | **FaCTOR:** Availability | **Typical:** LOW / L1

### DP-08: Secrets in code or config files

```python
API_KEY = "sk-abc123def456ghi789"
```

The secret is exposed to anyone with repository access, visible in CI logs, and baked into Docker images.
Rotation requires a code change and deployment; once committed, the secret is in git history forever.

**SEEMS:** Misconfiguration | **FaCTOR:** Fault isolation | **Typical:** HIGH / HYG (Irreversible — secret is in git history forever)

### DP-09: Dependencies on deployment order

Services must be deployed in a specific sequence (e.g. "deploy service B before service A") for the system to function correctly.
The ordering is fragile and poorly communicated; if violated by automation or a new team member, the system breaks.

**SEEMS:** Shared fate | **FaCTOR:** Fault isolation | **Typical:** MEDIUM / L2

---

## Review Checklist

A "no" answer is a potential finding; investigate before raising it.

- Are database migrations reversible using the add-before-remove pattern (add new column, migrate data, remove old column in a later release)?
- Do API changes maintain backward compatibility, or is a versioning strategy in place for breaking changes?
- Can each service be deployed independently without requiring coordinated changes to other services?
- Is new user-facing functionality gated behind a feature flag that can be disabled without a deployment?
- Can the deployment proceed without planned downtime (old and new versions coexist during rollout)?
- Are health checks updated to verify any new dependencies introduced by the change?
- Are operational parameters (timeouts, pool sizes, thresholds) externalised as configuration rather than hardcoded?
- Are all secrets loaded from a secrets manager or environment variables, with none committed to source control?

### Maturity Mapping

- **L1 (1.1):** Health checks updated for new functionality.
- **L1 (1.3):** Configurable values externalised (not hardcoded).
- **L2 (2.2):** Database migrations are reversible (add-before-remove pattern).
- **L3 (3.1):** Deployment can proceed without downtime (backward-compatible changes, coexistence of old and new versions).
