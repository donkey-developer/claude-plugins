# Calibration Examples — Architecture Domain

> Worked examples showing how to judge severity and maturity level for real code patterns. Use these to calibrate prompt output and verify consistency across reviews.

## How to use this document

Each example follows the same four-part structure used across all domain calibration documents:
1. **Code pattern** — what the reviewer sees
2. **Assessment** — severity, maturity level, zoom level
3. **Reasoning** — why this severity and level, not higher or lower
4. **Boundary note** — what would change the assessment up or down

---

## Code Level

### Example C1: God class with mixed responsibilities (HIGH / L1)

**Code pattern:**
```python
class OrderService:
    def create_order(self, items): ...
    def calculate_tax(self, amount): ...
    def send_email(self, recipient): ...
    def generate_pdf(self, order): ...
    def validate_credit_card(self, card): ...
    def sync_inventory(self, items): ...
```

**Assessment:** HIGH | L1 | Code | Separation of Concerns

**Reasoning:** Six unrelated responsibilities in one class — order lifecycle, tax calculation, email delivery, PDF generation, payment validation, and inventory management. Each responsibility has different reasons to change and different stakeholders. Testing any one responsibility requires constructing all dependencies. This is a clear L1 gap (module boundaries not explicit) and HIGH because the structural debt compounds — this class will attract more responsibilities over time.

**Boundary — would be MEDIUM / L1 if:**
```python
class OrderService:
    def create_order(self, items): ...
    def update_order(self, order_id, changes): ...
    def cancel_order(self, order_id): ...
    def get_order(self, order_id): ...
```
Four related operations on the same aggregate. The class has a clear responsibility (order lifecycle) even if it could be further decomposed. This is a minor improvement opportunity, not a fundamental design flaw.

**Boundary — would be HIGH / HYG if:** The God class handles both reads and writes to a shared database that other services also access (Total — changes cascade beyond the service boundary).

### Example C2: Domain depends on infrastructure (HIGH / L1)

**Code pattern:**
```python
from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship

class Order:
    __tablename__ = 'orders'
    id = Column(Integer, primary_key=True)
    customer_id = Column(Integer, ForeignKey('customers.id'))
    status = Column(String(50))
    items = relationship("OrderItem", back_populates="order")
```

**Assessment:** HIGH | L1 | Code | Loose Coupling / Testability

**Reasoning:** The domain entity `Order` is inseparable from SQLAlchemy. You cannot test order business logic without a database. You cannot change the persistence layer without rewriting the domain model. The ORM's constraints (e.g., lazy loading, session management) leak into business logic. This is a clear L1 gap (dependencies flow outward instead of inward) and HIGH because it fundamentally prevents the dependency rule from being followed.

**Boundary — would be MEDIUM / L1 if:**
```python
# Domain layer
class Order:
    def __init__(self, id: OrderId, customer_id: CustomerId, status: OrderStatus):
        self.id = id
        self.customer_id = customer_id
        self.status = status

# Infrastructure layer
class OrderMapping(Base):
    __tablename__ = 'orders'
    id = Column(Integer, primary_key=True)
    # ... mapping code separate from domain
```
The domain is separated but the mapping layer doesn't translate between domain and persistence models cleanly — some ORM conventions leak through. This is a partial implementation (L1) but not a fundamental violation.

### Example C3: Primitive obsession (MEDIUM / L1)

**Code pattern:**
```python
def transfer_money(
    from_account: str,     # Account ID as string
    to_account: str,       # Account ID as string
    amount: float,         # Money as float!
    currency: str          # Currency as string
):
    if amount <= 0:
        raise ValueError("Amount must be positive")
    if currency not in ["USD", "EUR", "GBP"]:
        raise ValueError("Invalid currency")
```

**Assessment:** MEDIUM | L1 | Code | High Cohesion

**Reasoning:** Business concepts (Account ID, Money, Currency) are represented as primitives. Validation logic is scattered in every function that handles money. `float` for money is a well-known bug source (rounding errors). However, this is MEDIUM (not HIGH) because it's a local quality issue — it doesn't create systemic coupling or cascading risk. It's an L1 gap because the code works but lacks the type-level safety that prevents an entire class of bugs.

**Boundary — would be HIGH / L1 if:** Multiple modules implement different validation rules for the same concept. One module accepts negative money amounts, another rejects them — the inconsistency is a business rule violation.

**Boundary — would be LOW / L2 if:** Only one function uses these primitives, and it's an internal utility that's not part of the public API.

### Example C4: Circular dependency between modules (HIGH / HYG)

**Code pattern:**
```python
# order/service.py
from billing.service import BillingService

class OrderService:
    def create_order(self, items):
        billing = BillingService()
        billing.charge(self.calculate_total(items))

# billing/service.py
from order.service import OrderService

class BillingService:
    def refund(self, order_id):
        orders = OrderService()
        order = orders.get_order(order_id)
```

**Assessment:** HIGH | HYG | Code | Loose Coupling (Total test: yes)

**Reasoning:** A circular dependency between `order` and `billing` modules. Neither can be extracted, tested, or deployed independently. If these become separate services, the circular dependency becomes a distributed deadlock risk. This triggers the Total test because extracting these modules into separate deployable units (a natural architectural evolution) is blocked — the coupling cascades beyond the current boundary.

**Boundary — would be HIGH / L1 if:** The cycle is within a single module (e.g., `order.models` imports `order.validation` which imports `order.models`). The coupling is bad but contained within one bounded context and fixable by restructuring the module.

---

## Service Level

### Example S1: Shared database between services (HIGH / HYG)

**Code pattern:** Service A's `OrderService` reads from the `orders` table. Service B's `AnalyticsService` also reads from and writes analytics metadata to the same `orders` table.

**Assessment:** HIGH | HYG | Service | Loose Coupling (Irreversible + Total)

**Reasoning:** Two services sharing the same database tables creates invisible coupling. Service A's schema migration can break Service B. Service B's writes can corrupt Service A's data. Neither can evolve independently. This triggers both Irreversible (data corruption across boundaries) and Total (schema change cascades to all consumers).

**Boundary — would be MEDIUM / L1 if:** Service B only reads (never writes) to the shared table, and there's a read-replica or view layer between them. The coupling is real but the corruption risk is lower.

### Example S2: Domain logic in controller (HIGH / L1)

**Code pattern:**
```python
@app.route("/orders", methods=["POST"])
def create_order():
    data = request.json
    if data["total"] > 1000:
        data["total"] *= 0.9  # VIP discount
    if data["shipping"] == "express":
        data["total"] += 15.00
    order = Order(**data)
    db.session.add(order)
    db.session.commit()
    send_confirmation_email(order)
    return jsonify(order.to_dict()), 201
```

**Assessment:** HIGH | L1 | Service | Separation of Concerns / Testability

**Reasoning:** Business logic (discount calculation, shipping surcharge) lives in the HTTP handler. Testing these rules requires making HTTP requests. The rules can't be reused from a CLI, message handler, or scheduled job. The controller will grow as more business rules are added — it's on the path to becoming a God class.

**Boundary — would be MEDIUM / L1 if:**
```python
@app.route("/orders", methods=["POST"])
def create_order():
    data = request.json
    order = order_service.create_order(data)  # Delegates to domain
    return jsonify(order.to_dict()), 201
```
The controller delegates to a domain service, but the domain service still imports infrastructure (database, email). Separation started but incomplete — a partial L1 improvement.

### Example S3: Missing error hierarchy (MEDIUM / L1)

**Code pattern:**
```python
class AppError(Exception):
    pass

# Every error path uses the same exception type
raise AppError("Order not found")
raise AppError("Database connection failed")
raise AppError("Invalid input: email required")
raise AppError("Payment service timeout")
```

**Assessment:** MEDIUM | L1 | Service | Explicit over Implicit

**Reasoning:** All errors use the same type — clients can't distinguish validation errors (don't retry) from infrastructure errors (retry) from business errors (handle differently). The error contract is implicit. This is MEDIUM because the service does signal errors (it's not swallowing them), but operators and clients can't make correct decisions from the error information.

**Boundary — would be HIGH / HYG if:** The generic error type masks data loss — e.g., a write that fails silently returns the same `AppError` as a validation failure, and the caller treats both as "bad input" instead of investigating.

---

## System Level

### Example Y1: Unprotected integration point (HIGH / HYG)

**Code pattern:**
```python
def get_user_profile(user_id):
    # Direct call to downstream service — no timeout, no circuit breaker
    response = requests.get(f"http://user-service/api/users/{user_id}")
    return response.json()
```

**Assessment:** HIGH | HYG | System | Loose Coupling (Total test: yes)

**Reasoning:** No timeout means a hung downstream service blocks the calling thread indefinitely. No circuit breaker means the caller keeps sending requests to a failing service. Under dependency failure, all worker threads can be consumed, making the calling service completely unresponsive. This is the "number-one killer of systems" per Nygard. Total: can render the entire calling service unresponsive.

**Boundary — would be MEDIUM / L1 if:**
```python
response = requests.get(
    f"http://user-service/api/users/{user_id}",
    timeout=(3, 10)
)
```
Timeout exists but no circuit breaker. The service won't hang indefinitely, but it still sends requests to a failing dependency (wasting resources). L1 gap — basic protection exists but failure isolation doesn't.

### Example Y2: Unbounded result set (HIGH / L1)

**Code pattern:**
```python
@app.route("/api/orders")
def list_orders():
    orders = order_repository.find_all()  # No limit, no pagination
    return jsonify([o.to_dict() for o in orders])
```

**Assessment:** HIGH | L1 | System | Explicit over Implicit

**Reasoning:** With 10 million orders, this serializes all records into memory, saturates the network, and likely times out. Even with fewer records, memory consumption grows linearly with data volume — the endpoint becomes a latent production incident.

**Boundary — would be MEDIUM / L2 if:**
```python
orders = order_repository.find_all(limit=1000)
```
There's a limit but no pagination, cursor, or streaming. The endpoint is bounded but can't be used for larger result sets. An L2 concern about API design maturity.

### Example Y3: Inconsistent error format across services (LOW / L1)

**Code pattern:**
Service A returns errors as `{"error": "not found"}`.
Service B returns errors as `{"code": 404, "message": "Not Found", "details": [...]}`.
Service C returns errors as plain text: `"Internal Server Error"`.

**Assessment:** LOW | L1 | System | Explicit over Implicit

**Reasoning:** Inconsistent error formats force every consumer to handle each service's error format differently. Error aggregation in monitoring is harder. However, this is LOW severity because each service still communicates errors — the inconsistency is an inconvenience, not a structural risk.

**Boundary — would be MEDIUM / L2 if:** The inconsistency is across the same team's services, indicating no shared error standard. An L2 governance concern.

---

## Landscape Level

### Example L1: Missing ADRs for major decisions (MEDIUM / L2)

**Code pattern:** The codebase uses Kafka for event streaming, PostgreSQL for persistence, and gRPC for inter-service communication. No ADR directory exists. No design docs explain why these technologies were chosen.

**Assessment:** MEDIUM | L2 | Landscape | Explicit over Implicit

**Reasoning:** When the team asks "why Kafka?" or "should we also use Kafka for this new feature?", there's no documented rationale. The decision may have been correct, but without context, every future decision is made without learning from past reasoning. This is an L2 gap — the system works, but governance and institutional knowledge are missing.

**Boundary — would be HIGH / L2 if:** A new team member has already introduced RabbitMQ for a new feature because they didn't know about the Kafka decision. Now the system has two messaging technologies with no documented rationale for either.

### Example L2: Stale tech-spec (MEDIUM / L2)

**Code pattern:** The `tech-spec.md` describes a REST-based architecture. The code has been migrated to gRPC for 3 of 5 services. Two ADRs document the migration, but the tech-spec still describes the original REST architecture.

**Assessment:** MEDIUM | L2 | Landscape | Explicit over Implicit

**Reasoning:** The tech-spec is actively misleading — a new developer reading it will assume REST everywhere. The ADRs document the change but aren't connected to the spec. This is an L2 gap — decisions are documented (ADRs) but the overall design document doesn't reflect them.

**Boundary — would be LOW / L3 if:** The tech-spec is mostly accurate with minor drift in non-critical details (e.g., lists a deprecated endpoint that still exists during sunset).

---

## Cross-level: How the same issue gets different assessments

### Shared database — assessed by different levels

The same shared database might be flagged by:

| Level | Emphasis |
|-------|----------|
| **Service** | "This service's domain model is corrupted by another service's schema assumptions" |
| **System** | "Schema migrations by one service can break the other" (this is the HYG finding) |
| **Landscape** | "No API boundary exists between these systems — data ownership is ambiguous" |

**During synthesis:** These merge into one finding. The System level's assessment (HYG / Total) takes precedence as the highest severity. The recommendation combines: "Define service APIs for data access (system), separate domain models from shared schema (service), document data ownership in the context map (landscape)."

### Domain logic in controllers — assessed by different levels

The same controller with embedded business logic might be flagged by:

| Level | Emphasis |
|-------|----------|
| **Code** | "Class has too many responsibilities — SRP violation" |
| **Service** | "Domain logic mixed with infrastructure — dependency rule violation" |

**During synthesis:** These merge into one finding. Both are L1, so the combined finding keeps L1. The recommendation combines: "Extract business logic to a domain service (code SRP), ensure the domain service has no infrastructure imports (service dependency rule)."
