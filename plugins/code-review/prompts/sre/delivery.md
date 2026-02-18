# Delivery

Can the service be deployed, rolled back, and configured safely without causing outages?

The Delivery pillar evaluates whether deployment practices, schema changes, API evolution, configuration management, and secret handling allow teams to ship changes safely and reverse them quickly if something goes wrong.
When this pillar is weak, deployments become high-risk events and rollbacks cause additional outages.

## Focus Areas

The Delivery pillar applies the SEEMS/FaCTOR duality through two specific lenses.

### SEEMS focus (how the code fails)

- **Misconfiguration** — Configuration values, secrets, and feature flags that cannot be changed without a deployment extend the blast radius of incidents.
  When you can only respond by deploying, the incident drags on while CI/CD runs.
- **Shared fate** — Breaking API changes, coordinated deployment requirements, and deployment-order dependencies couple the fate of multiple services.
  When one deploy fails, it takes others down with it.

### FaCTOR focus (what should protect against failure)

- **Output correctness** — API contracts must be backward-compatible during rollouts.
  When old and new instances coexist during a rolling deploy, every request must be handled correctly by both versions.
- **Availability** — Feature flags provide a kill switch without a deploy.
  Hardcoded values and removed flags eliminate the ability to respond to incidents without a full deployment cycle.
- **Fault isolation** — Deployments must not create hard ordering dependencies between services.
  If Service A must deploy before Service B, a failed deploy leaves the system in a broken intermediate state.

## Anti-Pattern Catalogue

### DP-01: Non-reversible database migration

```sql
ALTER TABLE users DROP COLUMN legacy_email;
ALTER TABLE users RENAME COLUMN new_email TO email;
```

**Why it matters:** If the new code has a bug and needs rollback, the old code expects the dropped or renamed schema.
Rollback requires a backup restore, which means unplanned downtime and potential data loss.
SEEMS: Misconfiguration (deployment error causes data loss).
FaCTOR: Output correctness (old and new versions cannot coexist).
Typical severity: HIGH / HYG (Irreversible -- data and schema are permanently changed).

### DP-02: Breaking API change without versioning

Removing or renaming a field in an API response, changing the type of a field, or removing an endpoint without maintaining the previous contract.

**Why it matters:** Existing clients break immediately.
During a rolling or canary deployment, some requests hit old instances and some hit new ones -- causing intermittent failures that are hard to diagnose and impossible to avoid without rollback.
SEEMS: Shared fate (deployment affects all consumers simultaneously).
FaCTOR: Output correctness (inconsistent results during rollout).
Typical severity: HIGH / L1.

### DP-03: Config change requires coordinated deployment

A config value in Service A that must match a corresponding value in Service B.
Updating one without the other causes failures.

**Why it matters:** Coordinated deployments are fragile.
If one deploy succeeds and the other fails or is delayed, the system is in an inconsistent state with no safe intermediate position.
SEEMS: Shared fate (services coupled through config).
FaCTOR: Fault isolation (one service's deployment failure cascades to others).
Typical severity: MEDIUM / L2.
Escalates to HIGH / HYG if the inconsistent state causes data corruption (Irreversible) or cascading failure (Total).

### DP-04: Removing feature flag before stabilisation

A feature flag removed from code (behaviour hardcoded to the new path) before the feature has run in production long enough to confirm stability.

**Why it matters:** If a latent bug surfaces after flag removal, the only remediation is a full code rollback.
With the flag in place, the team could disable the feature in seconds without a deployment cycle.
SEEMS: Misconfiguration (no way to disable the feature).
FaCTOR: Availability (no kill switch for the new behaviour).
Typical severity: MEDIUM / L2.

### DP-05: Deployment requires downtime

A change that requires stopping the old version before starting the new one -- because they cannot coexist, or because a migration requires exclusive database access.

**Why it matters:** Every deployment becomes a planned outage.
Deployment frequency is constrained by maintenance windows.
Hotfixes that are needed immediately must wait for scheduled downtime.
SEEMS: Shared fate (deployment and availability are coupled).
FaCTOR: Availability (service unavailable during deployment).
Typical severity: MEDIUM / L3.

### DP-06: Missing health check for new functionality

A new feature or endpoint is added but the health check is not updated to verify the new functionality's dependencies.

**Why it matters:** The health check reports "healthy" even when the new feature's dependencies are down.
Traffic is routed to instances that cannot serve the new feature, causing errors for users of that feature with no signal to the orchestrator.
SEEMS: Misconfiguration (health check does not reflect true readiness).
FaCTOR: Availability.
Typical severity: MEDIUM / L1.

### DP-07: Hardcoded values that should be configurable

```python
TIMEOUT_SECONDS = 30      # hardcoded
POOL_SIZE = 10            # hardcoded
SERVICE_URL = "https://api.example.com"  # hardcoded
```

**Why it matters:** Changing these values requires a code change and deployment.
During an incident, teams cannot adjust behaviour (increase timeout, reduce pool size, redirect traffic) without triggering a full deployment cycle.
SEEMS: Misconfiguration (cannot adjust without deploy).
FaCTOR: Availability (cannot respond to incidents with config changes alone).
Typical severity: LOW / L1.

### DP-08: Secrets in code or config files

```python
API_KEY = "sk-abc123..."
DATABASE_URL = "postgresql://user:password@host/db"
```

**Why it matters:** Secrets committed to source code are exposed to everyone with repository access, end up in CI logs, Docker images, and backups, and cannot be rotated without a code change and deploy.
Once in git history, the secret is permanently exposed even after it is removed.
SEEMS: Misconfiguration.
FaCTOR: Fault isolation (a compromised secret affects everything that uses it).
Typical severity: HIGH / HYG (Irreversible -- once committed, the secret is in git history permanently).

### DP-09: Dependencies on deployment order

Service A must be deployed before Service B, or a database migration must complete before Service C starts, with no mechanism to enforce or verify the order.

**Why it matters:** Deployment ordering is fragile and poorly communicated.
If the order is violated -- by automation, by a new team member, or by parallel deploys -- the system enters a broken state that is difficult to diagnose and recover from.
SEEMS: Shared fate (services coupled through deployment order).
FaCTOR: Fault isolation (one deployment's timing affects the correctness of others).
Typical severity: MEDIUM / L2.

## Review Checklist

When assessing the Delivery pillar, work through each item in order.

1. **Schema migration safety** -- Are database migrations reversible? Do destructive operations (`DROP COLUMN`, `RENAME COLUMN`, type narrowing) follow a two-phase add-before-remove pattern?
2. **API backward compatibility** -- Are API changes backward-compatible during a rolling deployment? Are fields removed or renamed without a versioning strategy?
3. **Config decoupling** -- Do config changes in one service require a simultaneous change in another? Are there config values that must match across service boundaries?
4. **Feature flag hygiene** -- Are feature flags retained long enough to confirm production stability before removal? Are new high-risk behaviours deployed without flags?
5. **Zero-downtime deployment** -- Can old and new versions run simultaneously during a rolling deploy? Are there lock-step deployment requirements that mandate downtime?
6. **Health check completeness** -- When new features or dependencies are added, is the health check updated to verify them?
7. **Configurability** -- Are operationally important values (timeouts, pool sizes, URLs, thresholds) externalised to config rather than hardcoded?
8. **Secret management** -- Are secrets loaded from a secret manager or environment variables rather than committed to source code or config files?
9. **Deployment order independence** -- Can services be deployed in any order without entering a broken intermediate state?

## Severity Framing

Severity for Delivery findings is about reversibility -- what happens if something goes wrong and the team needs to undo the change.

- **Irreversible changes** -- Schema drops, committed secrets, and breaking API changes during a rolling deploy are Hygiene findings because they cannot be safely undone once deployed.
  Recovery requires restoring from backup (downtime) or accepting permanent data or security exposure.
- **Lost kill switch** -- Hardcoded values and removed feature flags eliminate the ability to respond to incidents without a full deployment.
  In a live incident, minutes matter -- a config change takes seconds while a deployment takes minutes or hours.
- **Fragile coordination** -- Deployment order dependencies and coordinated config changes create failure modes that are invisible in testing but surface at the worst possible time during a production incident or routine deploy.
