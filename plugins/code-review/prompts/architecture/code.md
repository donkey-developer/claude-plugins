## Code Level — Is the Code Well-Structured?

The Code level examines classes, functions, and modules — the innermost structural units.
It evaluates whether code is well-structured for change, testing, and understanding.

## Focus Areas

- **Responsibility clarity** — each component has a single, well-defined purpose.
  Flag classes with too many responsibilities: more than ~500 lines, ~10+ dependencies, methods on unrelated data (often named `*Manager`, `*Service`, `*Helper`, `*Utils`).
- **Dependency direction** — business logic does not import infrastructure frameworks.
  Domain classes should not inherit from ORM base classes, use persistence annotations, or call HTTP/filesystem APIs directly.
- **Coupling** — the dependency graph between modules is a directed acyclic graph.
  No circular dependencies, direct or transitive; modules can be extracted, tested, and deployed independently.
- **Cohesion** — related behaviour is grouped together.
  Methods primarily operate on their own class's data; business concepts are encapsulated near the data they govern.
- **Type safety of domain concepts** — business concepts (IDs, money, emails, currencies) are represented as typed values, not raw primitives; validation is encapsulated at the type level.
- **Testability** — dependencies are injectable; side effects are behind substitutable interfaces.
  Business logic can be unit tested without infrastructure.
- **Naming** — domain concepts use consistent vocabulary within each bounded context.
  Technical implementation names do not leak into the domain layer.
- **Inheritance depth** — prefer composition; hierarchies deeper than 2-3 levels distribute behaviour unpredictably and risk substitution violations.
- **Dead code and premature abstraction** — interfaces with only one implementation "just in case", unused code paths "that might be needed later"; abstractions should earn their existence.

## Anti-Patterns

### CL-01: God class

A class with too many responsibilities — more than ~500 lines, ~10+ dependencies, methods on unrelated data.
Often named `*Manager`, `*Service`, `*Helper`, `*Utils`.
**Principle:** Separation of Concerns | **Severity:** HIGH / L1

### CL-02: Circular dependency

Module A imports Module B, and Module B imports Module A (directly or transitively).
Neither module can be extracted, tested, or deployed independently.
**Principle:** Loose Coupling | **Severity:** HIGH / HYG

### CL-03: Leaky abstraction — persistence in domain

Domain classes import ORM or persistence frameworks.
Business logic cannot be tested without a database; changing persistence requires rewriting domain logic.

```python
from sqlalchemy import Column, Integer, String
class Order:
    id = Column(Integer, primary_key=True)
    status = Column(String)
```

**Principle:** Loose Coupling, Testability | **Severity:** HIGH / L1

### CL-04: Primitive obsession

Raw strings for emails, raw ints for IDs, raw floats for money — instead of typed values.
Validation is scattered; invalid values compile and pass silently.

```python
def create_order(user_id: int, email: str, amount: float, currency: str): ...  # primitives
def create_order(user_id: UserId, email: Email, price: Money): ...              # typed values
```

**Principle:** High Cohesion, Explicit over Implicit | **Severity:** MEDIUM / L1

### CL-05: Anaemic domain model

Classes with only getters/setters and no behaviour.
All business logic lives in separate service classes operating on dumb data containers.
**Principle:** High Cohesion | **Severity:** MEDIUM / L1

### CL-06: Feature envy

A method uses another class's data more than its own — chains of `obj.getX().getY().doZ()`.
The method should probably live on the class it envies.
**Principle:** High Cohesion, Loose Coupling | **Severity:** MEDIUM / L1

### CL-07: Deep inheritance hierarchy

More than 2-3 levels of class inheritance.
Behaviour is distributed across the hierarchy; changes to base classes ripple unpredictably.
**Principle:** Separation of Concerns, Testability | **Severity:** MEDIUM / L2

### CL-08: Hidden dependencies

A class constructs its own dependencies internally rather than receiving them through injection.
The dependency graph is invisible from the constructor or public interface.
**Principle:** Testability, Explicit over Implicit | **Severity:** MEDIUM / L1

### CL-09: Inconsistent naming

The same domain concept referred to by multiple names across layers or modules.
Technical implementation names appear in the domain layer instead of domain terms.
**Principle:** Explicit over Implicit | **Severity:** MEDIUM / L1

### CL-10: Dead code and premature abstraction

Interfaces with only one implementation, abstract factories for a single variant, unused code paths.
Adds cognitive load without value; the abstraction may be wrong for the actual future requirement.
**Principle:** Separation of Concerns | **Severity:** LOW / L2

## Checklist

- [ ] Does each class/module have a single, well-defined responsibility?
- [ ] Does business logic avoid importing infrastructure frameworks?
- [ ] Are there circular dependencies between modules?
- [ ] Can components be tested without standing up infrastructure?
- [ ] Are domain concepts represented as typed values rather than raw primitives?
- [ ] Is related behaviour grouped in the same module, or scattered?
- [ ] Are there classes with deep inheritance hierarchies (>2-3 levels)?
- [ ] Is dead code or premature abstraction present (interfaces with one implementation, unused paths)?
- [ ] Is naming consistent with the domain vocabulary within each bounded context?
- [ ] Are hidden dependencies present (internally constructed rather than injected)?

## Positive Indicators

- Clear module boundaries with intentional public interfaces.
- Dependencies flow inward — infrastructure depends on domain.
- Business logic testable in isolation without infrastructure.
- Consistent domain vocabulary across the module.
