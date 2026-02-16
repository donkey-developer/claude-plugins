# Anti-Patterns Catalogue — Architecture Domain

> Complete catalogue of structural patterns that Architecture reviewers should flag. Organised by zoom level, with design principle classification and typical severity.

## How to use this document

Each anti-pattern includes:
- **Pattern name** — a short, memorable label
- **What it looks like** — concrete code or structural description
- **Why it's bad** — structural impact over time
- **Design principle violated** — which cross-cutting principle is eroded
- **Typical severity** — default assessment (may be higher or lower depending on context)

When adding new anti-patterns to prompts, follow this structure. Use concrete descriptions, not abstract categories.

---

## Code Level Anti-Patterns

### CL-01: God class

**What it looks like:** A class with too many responsibilities — more than ~500 lines, more than ~10 dependencies, methods that operate on unrelated data. Often named `*Manager`, `*Service`, `*Helper`, `*Utils`.

**Why it's bad:** Every change to any responsibility risks breaking the others. Testing requires constructing the entire class with all its dependencies. The class becomes a merge conflict magnet. New developers can't understand it in a reasonable time.

**Design principle:** Separation of Concerns
**Typical severity:** HIGH / L1

### CL-02: Circular dependency

**What it looks like:** Module A imports from Module B, and Module B imports from Module A (directly or transitively).

**Why it's bad:** Neither module can be extracted, tested, or deployed independently. Changes to either module may break the other. Circular dependencies compound — once one exists, more are attracted into the cycle.

**Design principle:** Loose Coupling
**Typical severity:** HIGH / HYG (Total — if the cycle spans services, one failure cascades to all participants)

### CL-03: Leaky abstraction — persistence in domain

**What it looks like:** Domain classes import ORM or persistence frameworks. `@Entity`, `@Column`, `@Table` annotations on domain objects. SQLAlchemy `Column` types in domain models.

```python
# BAD: Domain depends on infrastructure
from sqlalchemy import Column, Integer, String

class Order:
    id = Column(Integer, primary_key=True)
    status = Column(String)
```

**Why it's bad:** The domain model can't be tested without a database. Changing the persistence layer requires rewriting domain logic. The ORM's constraints leak into business rules.

**Design principle:** Loose Coupling, Testability
**Typical severity:** HIGH / L1

### CL-04: Primitive obsession

**What it looks like:** Using raw strings for emails, raw ints for IDs, raw floats for money, raw strings for currencies — instead of typed value objects.

```python
# BAD: Primitives everywhere
def create_order(user_id: int, email: str, amount: float, currency: str): ...

# GOOD: Value objects
def create_order(user_id: UserId, email: Email, price: Money): ...
```

**Why it's bad:** No validation at the type level — invalid emails, negative money, wrong currency pairs all compile and pass. Business rules about these concepts are scattered across the codebase instead of encapsulated.

**Design principle:** High Cohesion, Explicit over Implicit
**Typical severity:** MEDIUM / L1

### CL-05: Anemic domain model

**What it looks like:** Classes with only getters/setters and no behaviour. All business logic lives in separate "service" classes that operate on dumb data containers.

**Why it's bad:** Domain knowledge is scattered across service classes rather than encapsulated in the entities that own the data. The "service" classes become God classes. The domain model communicates nothing about business rules.

**Design principle:** High Cohesion
**Typical severity:** MEDIUM / L1

### CL-06: Feature envy

**What it looks like:** A method that uses another class's data more than its own. Chains of `obj.getX().getY().doZ()` — reaching deep into another object's structure.

**Why it's bad:** The method should probably live on the class it's envying. The calling class knows too much about the other's internal structure. Changes to the other class break the calling method.

**Design principle:** High Cohesion, Loose Coupling
**Typical severity:** MEDIUM / L1

### CL-07: Deep inheritance hierarchy

**What it looks like:** More than 2-3 levels of class inheritance. Abstract base classes with many methods, some overridden, some not.

**Why it's bad:** Behaviour is distributed across the hierarchy — you must read all parent classes to understand a method's full behaviour. Liskov Substitution violations are common. Changes to base classes ripple unpredictably.

**Design principle:** Separation of Concerns, Testability
**Typical severity:** MEDIUM / L2

### CL-08: Hidden dependencies

**What it looks like:** A class constructs its own dependencies internally rather than receiving them through injection. Uses of `new`, `static` factory methods, service locators, or global state inside business logic.

**Why it's bad:** Can't substitute dependencies for testing. Can't change implementations without modifying the class. The dependency graph is invisible from the constructor/public interface.

**Design principle:** Testability, Explicit over Implicit
**Typical severity:** MEDIUM / L1

### CL-09: Inconsistent naming (ubiquitous language violation)

**What it looks like:** The same domain concept referred to by multiple names: "Portfolio" in the API, "Orders" in the database, "Basket" in the UI. Or technical implementation names in the domain layer ("DbRecord", "HttpHandler") instead of domain terms.

**Why it's bad:** New developers can't map between business requirements and code. Domain experts can't review or validate the model. Miscommunication between teams becomes structural.

**Design principle:** Explicit over Implicit
**Typical severity:** MEDIUM / L1

### CL-10: Dead code and premature abstraction

**What it looks like:** Interfaces with only one implementation ("just in case"). Abstract factories for a single variant. Unused code paths that "might be needed later". YAGNI violations.

**Why it's bad:** Adds cognitive load without value. The abstraction may be wrong for the actual future requirement. Dead code misleads — developers assume it's used.

**Design principle:** Separation of Concerns
**Typical severity:** LOW / L2

---

## Service Level Anti-Patterns

### SL-01: Shared database

**What it looks like:** Two services reading from or writing to the same database tables. Direct SQL access to another service's schema. Shared ORMs or database models.

**Why it's bad:** Creates invisible coupling — changes to the schema by one team break the other. Independent deployment is impossible. Data ownership is ambiguous. Migrations become coordinated events.

**Design principle:** Loose Coupling, Explicit over Implicit
**Typical severity:** HIGH / HYG (Irreversible — if both services write to shared tables, data corruption can occur. Total — schema changes cascade to all consumers)

### SL-02: Distributed monolith

**What it looks like:** Services that must be deployed together. Shared libraries containing domain logic. Synchronous call chains where all services must be running for any to work.

**Why it's bad:** All the operational complexity of microservices with none of the benefits. Deployment is all-or-nothing. A failure in one service cascades to all. Teams can't work independently.

**Design principle:** Loose Coupling
**Typical severity:** HIGH / HYG (Total — one deployment failure or service outage cascades to all)

### SL-03: Domain logic in controllers

**What it looks like:** Business rules implemented in HTTP handlers, API controllers, or message handlers. Validation, calculation, and orchestration in the request handling layer.

```python
# BAD: Domain logic in HTTP handler
@app.route("/orders", methods=["POST"])
def create_order():
    if request.json["total"] > 1000:
        # Apply discount - this is domain logic!
        request.json["total"] *= 0.9
    db.session.add(Order(**request.json))
```

**Why it's bad:** The business logic can't be tested without HTTP. It can't be reused from a CLI, message handler, or scheduled job. The controller grows into a God class. The "domain" is invisible — it exists only in the plumbing.

**Design principle:** Separation of Concerns, Testability
**Typical severity:** HIGH / L1

### SL-04: Service too broad

**What it looks like:** A single service serving multiple bounded contexts — unrelated features, different change cadences, different stakeholders. Often identifiable by "AND" in the service description: "manages users AND handles billing AND sends notifications".

**Why it's bad:** Every team's changes risk breaking other teams' features. The service grows without bound. Deployment frequency is constrained by the slowest-moving feature. The domain model becomes internally inconsistent.

**Design principle:** Separation of Concerns, High Cohesion
**Typical severity:** MEDIUM / L1

### SL-05: Missing Anti-Corruption Layer

**What it looks like:** External DTOs or upstream models used directly throughout domain code. Third-party data structures passed into business logic without translation.

**Why it's bad:** The upstream system's model dictates the downstream domain's structure. When the upstream changes, ripple effects propagate deep into domain logic. The downstream team loses control of their own model.

**Design principle:** Loose Coupling, Explicit over Implicit
**Typical severity:** MEDIUM / L1

### SL-06: Chatty interface

**What it looks like:** A client needs 5+ API calls to complete one logical operation. Fine-grained CRUD endpoints with no aggregate operations.

**Why it's bad:** Network latency is multiplied. Partial failure handling becomes complex (3 of 5 calls succeed — now what?). Clients must understand the service's internal structure to compose the correct sequence.

**Design principle:** High Cohesion, Explicit over Implicit
**Typical severity:** MEDIUM / L2

### SL-07: Missing error hierarchy

**What it looks like:** All errors treated the same — no distinction between transient (timeout, rate limit), permanent (validation failure, not found), and infrastructure (connection refused, disk full) errors.

**Why it's bad:** Clients can't make correct retry decisions. Operators can't distinguish "expected" errors from "requires investigation" errors. Monitoring treats all errors as equal severity.

**Design principle:** Explicit over Implicit
**Typical severity:** MEDIUM / L1

### SL-08: Layer bypass

**What it looks like:** Some features follow the layered architecture (domain → application → infrastructure), others skip layers — a controller calling the database directly, or infrastructure calling domain objects directly.

**Why it's bad:** Inconsistent architecture is harder to reason about than consistently wrong architecture. Developers don't know which pattern to follow. The bypass becomes the precedent for future shortcuts.

**Design principle:** Separation of Concerns
**Typical severity:** LOW / L1

---

## System Level Anti-Patterns

### YL-01: Unprotected integration point

**What it looks like:** External call with no timeout, no circuit breaker, no error handling. A raw HTTP/gRPC call to a downstream service with no protection.

```python
# BAD: No timeout, no circuit breaker
response = requests.get(f"http://downstream/api/data")

# GOOD: Protected with timeout and circuit breaker
response = requests.get(
    f"http://downstream/api/data",
    timeout=(3, 10)
)
```

**Why it's bad:** A slow or failing dependency can block all calling threads. Under dependency failure, the caller becomes unresponsive. This is "the number-one killer of systems" (Nygard).

**Design principle:** Loose Coupling, Explicit over Implicit
**Typical severity:** HIGH / HYG (Total — can render the entire calling service unresponsive)

### YL-02: Cascading failure path

**What it looks like:** A synchronous call chain (A → B → C → D) where one service's failure brings down all upstream callers. No bulkheads, no circuit breakers, no fallbacks between services.

**Why it's bad:** The blast radius of any single service failure is the entire chain. Recovery requires restarting in reverse order. The weakest service determines the reliability of the entire chain.

**Design principle:** Loose Coupling
**Typical severity:** HIGH / HYG (Total — one failure cascades beyond its boundary)

### YL-03: Unbounded result sets

**What it looks like:** Cross-service queries that return unbounded results — `getAllOrders()`, `findUsers()` with no pagination, limit, or streaming.

```python
# BAD: Could return millions of records
orders = order_service.get_all_orders()

# GOOD: Bounded and paginated
orders = order_service.get_orders(page=1, limit=100)
```

**Why it's bad:** Memory exhaustion. Network saturation. Timeout cascades. One large response can overwhelm the caller, the network, and the downstream service simultaneously.

**Design principle:** Explicit over Implicit
**Typical severity:** HIGH / L1

### YL-04: Shared database across services

**What it looks like:** Multiple services accessing the same database tables. One service writing, another reading. Shared connection pools or database credentials.

**Why it's bad:** Schema changes break unknown consumers. Locking contention between services causes unpredictable latency. Data ownership is ambiguous — who decides the schema?

**Design principle:** Loose Coupling
**Typical severity:** HIGH / HYG (Total — schema change by one team breaks all services using the table)

### YL-05: Temporal coupling

**What it looks like:** Service A must call B before C. Operations have implicit ordering requirements that aren't enforced by the API.

**Why it's bad:** Out-of-order calls produce silent data corruption or confusing errors. The ordering constraint exists only in developer knowledge, not in the code.

**Design principle:** Explicit over Implicit
**Typical severity:** MEDIUM / L2

### YL-06: Missing contract

**What it looks like:** Services communicate via HTTP/gRPC/messaging with no formal contract definition — no OpenAPI, no Protobuf, no AsyncAPI. "It just calls that endpoint."

**Why it's bad:** Breaking changes are discovered at runtime, not at build time. Consumer expectations are undocumented. Version management is impossible.

**Design principle:** Explicit over Implicit
**Typical severity:** MEDIUM / L1

### YL-07: Dogpile / thundering herd

**What it looks like:** All instances expire cache entries at the same time, all hit the database simultaneously. Or: all clients that failed retry at the same moment.

**Why it's bad:** Creates a periodic spike of load on the downstream service. Can cause cascading failure if the spike exceeds the downstream's capacity.

**Design principle:** Loose Coupling
**Typical severity:** MEDIUM / L2

### YL-08: Synchronous call to non-critical dependency

**What it looks like:** A user-facing request handler that makes a synchronous call to analytics, recommendations, audit logging, or other non-critical services in the request path.

**Why it's bad:** Non-critical dependency failure degrades or blocks the critical user-facing path. The non-critical service effectively becomes a hard dependency.

**Design principle:** Separation of Concerns
**Typical severity:** MEDIUM / L2

---

## Landscape Level Anti-Patterns

### LL-01: Distributed big ball of mud

**What it looks like:** No clear boundaries between systems. Everything calls everything. Any change requires coordinating across many teams. No context map exists.

**Why it's bad:** Change velocity slows to the speed of the slowest team. Integration failures are unpredictable. Nobody understands the full system. Ownership is ambiguous.

**Design principle:** Separation of Concerns, Explicit over Implicit
**Typical severity:** HIGH / L1

### LL-02: Undocumented integration points

**What it looks like:** Services connected with no formal contract. "It just calls that endpoint." No OpenAPI, no AsyncAPI, no documented message formats.

**Why it's bad:** Breaking changes are discovered in production. New teams can't integrate without tribal knowledge. Migration paths are invisible.

**Design principle:** Explicit over Implicit
**Typical severity:** HIGH / L1

### LL-03: Shared database across system boundaries

**What it looks like:** Multiple systems (owned by different teams or organisations) writing to the same database.

**Why it's bad:** All the problems of shared database at the service level, compounded by organisational boundaries. Schema governance is a political nightmare. Data ownership disputes become inter-team conflicts.

**Design principle:** Loose Coupling
**Typical severity:** HIGH / HYG (Irreversible — data corruption across organisational boundaries)

### LL-04: Missing ADRs for significant decisions

**What it looks like:** Major technology or architecture choices with no documented rationale. "Why did we choose Kafka?" — nobody knows. Decisions live only in people's heads.

**Why it's bad:** The next team to encounter the constraint will re-evaluate the same options, possibly making an inconsistent choice. When the decision-maker leaves, the rationale leaves with them.

**Design principle:** Explicit over Implicit
**Typical severity:** MEDIUM / L2

### LL-05: Stale documentation / design-code drift

**What it looks like:** Tech-spec or design docs that don't match the current codebase. ADRs accepted but tech-spec unchanged. Code evolved beyond what any documentation describes.

**Why it's bad:** Documentation becomes actively misleading — worse than no documentation. New developers make incorrect assumptions. Architecture reviews assess the wrong system.

**Design principle:** Explicit over Implicit
**Typical severity:** MEDIUM / L2

### LL-06: Spaghetti integration

**What it looks like:** Point-to-point connections everywhere. N services with N*(N-1)/2 direct connections. No event bus, no API gateway, no shared messaging infrastructure.

**Why it's bad:** Adding a new service requires connecting to every existing service. Connection failures are multiplicative. No single place to observe or manage cross-system communication.

**Design principle:** Loose Coupling
**Typical severity:** MEDIUM / L2

### LL-07: Golden hammer

**What it looks like:** Same technology for every problem — Kafka for request/response, REST for event streaming, relational database for everything.

**Why it's bad:** Forces inappropriate design patterns. Teams fight the tool instead of solving the problem. Technical debt accumulates when workarounds replace proper solutions.

**Design principle:** Separation of Concerns
**Typical severity:** MEDIUM / L2

### LL-08: No fitness functions

**What it looks like:** Architecture standards exist on paper but aren't enforced. No automated tests for layer violations, circular dependencies, API compatibility, or performance budgets.

**Why it's bad:** Architecture erodes silently. Layer violations accumulate. Circular dependencies appear one import at a time. By the time anyone notices, the cost of correction is prohibitive.

**Design principle:** Explicit over Implicit
**Typical severity:** LOW / L3 (escalates to MEDIUM if architectural standards exist but aren't enforced)

---

## Adding New Anti-Patterns

When adding a new anti-pattern to this catalogue or to the prompts:

1. Give it a **short, memorable name** (not "Bad Practice #7")
2. Describe **what it looks like** in code or structure (concrete, not abstract)
3. Explain **why it's bad** in terms of structural impact over time
4. Identify the **design principle** being violated
5. Assign a **typical severity** with reasoning
6. Note **boundary conditions** that would change the severity (especially HYG escalation)
