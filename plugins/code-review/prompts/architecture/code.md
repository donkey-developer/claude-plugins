# Code

Is the code well-structured?

The Code zoom level evaluates whether individual classes, functions, and modules are well-designed.
A weak Code level is characterised by classes that are hard to understand, test, or change without breaking unrelated behaviour.

## Focus Areas

### Design Principles focus (what should this look like?)

- **Separation of concerns** — Each class or module has a single, clearly defined purpose.
  A class with more than ~500 lines, more than ~10 dependencies, or methods that operate on unrelated data likely violates this principle.
- **Loose coupling** — Modules depend on abstractions, not concrete implementations.
  The dependency graph between modules is a directed acyclic graph with no cycles.
- **High cohesion** — Related behaviour lives together.
  A method that uses another class's data more than its own is a signal of misplaced behaviour.
- **Testability** — Business logic can be exercised without infrastructure.
  Dependencies are injectable; side effects are isolated behind interfaces.

### Erosion Patterns focus (how does this go wrong?)

- **God class** — A class accumulating too many responsibilities.
  Often named `*Manager`, `*Service`, `*Helper`, or `*Utils`.
  Every change risks breaking unrelated behaviour.
- **Circular dependency** — Module A imports Module B, and Module B imports Module A.
  Neither can be extracted, tested, or deployed independently.
- **Persistence in domain** — Infrastructure frameworks (ORM annotations, SQL queries) appear in domain classes.
  Business logic cannot be tested without a database.
- **Primitive obsession** — Domain concepts (email, money, identifier) represented as raw strings or numbers.
  Validation rules are scattered rather than encapsulated.
- **Hidden dependencies** — A class constructs its own dependencies internally.
  The dependency graph is invisible from the constructor or public interface.

## Anti-Pattern Catalogue

### CL-01: God class

```python
class OrderService:
    def create_order(self, items): ...
    def calculate_tax(self, amount): ...
    def send_email(self, recipient): ...
    def generate_pdf(self, order): ...
    def validate_credit_card(self, card): ...
    def sync_inventory(self, items): ...
```

**Why it matters:** Six unrelated responsibilities in one class.
Every change to one responsibility risks breaking the others.
Testing requires constructing all dependencies simultaneously.
Erosion pattern: Mixed responsibilities.
Typical severity: HIGH / L1.

### CL-02: Circular dependency

```python
# order/service.py
from billing.service import BillingService

# billing/service.py
from order.service import OrderService
```

**Why it matters:** Neither module can be extracted, tested, or deployed independently.
Circular dependencies compound — once one exists, more are attracted.
Erosion pattern: Tight coupling.
Typical severity: HIGH / HYG (Total — if the cycle spans services, one failure cascades to all participants).

### CL-03: Persistence in domain

```python
# BAD: Domain depends on infrastructure
from sqlalchemy import Column, Integer, String

class Order:
    id = Column(Integer, primary_key=True)
    status = Column(String)
```

**Why it matters:** The domain model cannot be tested without a database.
Changing the persistence layer requires rewriting domain logic.
Erosion pattern: Hidden dependencies.
Typical severity: HIGH / L1.

### CL-04: Primitive obsession

```python
# BAD: Primitives everywhere
def create_order(user_id: int, email: str, amount: float, currency: str): ...
```

**Why it matters:** No validation at the type level — invalid emails, negative amounts, and mismatched currency pairs all compile and pass.
Business rules about these concepts are scattered rather than encapsulated.
Erosion pattern: Scattered behaviour.
Typical severity: MEDIUM / L1.

### CL-05: Hidden dependencies

```python
class OrderService:
    def __init__(self):
        self.db = DatabaseConnection()        # hidden
        self.email = EmailClient()            # hidden
        self.cache = RedisCache()             # hidden
```

**Why it matters:** Dependencies cannot be substituted for testing.
The class's full cost is invisible from its public interface.
Erosion pattern: Hidden dependencies, Magic and indirection.
Typical severity: MEDIUM / L1.

## Review Checklist

When assessing the Code zoom level, work through each item in order.

1. **Responsibility scope** — Does each class have a single, clearly defined purpose?
   Does any class exceed ~500 lines or have more than ~10 distinct dependencies?
2. **Dependency direction** — Do domain and business logic classes import infrastructure frameworks (databases, HTTP clients, messaging)?
   The answer should be no.
3. **Circular dependencies** — Are there any import cycles between modules or packages?
   Check both direct and transitive cycles.
4. **Testability** — Can business logic be unit tested without a running database, HTTP server, or message broker?
   Are dependencies injectable or constructed internally?
5. **Domain vocabulary** — Are domain concepts (identifiers, money, status, dates) represented as typed objects or as raw primitives?
6. **Behaviour placement** — Are there methods that use another class's data more than their own?
   Is business logic scattered across many classes rather than encapsulated in the class that owns the data?

## Severity Framing

Severity for Code findings is about structural consequence — how much harder will the system be to change, test, and extend if this ships.

- **Circular dependencies and domain-infrastructure coupling** — These are structural blockers.
  They prevent independent testing, prevent safe extraction, and compound over time.
  Typically HIGH or HYG.
- **God classes and anemic domain models** — These accumulate technical debt.
  Every new feature makes them harder to work with.
  Typically HIGH / L1 when the class is already large; MEDIUM / L1 when still early.
- **Primitive obsession and missing value objects** — These scatter business rules.
  The cost is in maintenance and bug risk, not immediate structural failure.
  Typically MEDIUM / L1.
- **Minor naming and style issues** — Inconvenient but not structurally dangerous.
  Typically LOW / L2.
