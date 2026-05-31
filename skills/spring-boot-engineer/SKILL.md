---
name: spring-boot-engineer
description: Generates Spring Boot 3.x applications organized as a monolith by bounded context, creates layered REST features (api/domain/application/infra), implements Spring Security 6 authentication flows, sets up Spring Data JPA repositories, and standardizes error handling and observability. Use when building Spring Boot 3.x monolithic applications; invoke for Spring Data JPA, Spring Security 6, Java REST API design, domain-driven package structure, error handling, or observability.
license: MIT
metadata:
  author: https://github.com/Jeffallan
  version: "2.0.0"
  domain: backend
  triggers: Spring Boot, Spring Framework, Spring Security, Spring Data JPA, Java REST API, Bounded Context, Domain-Driven Design, Monolith
  role: specialist
  scope: implementation
  output-format: code
  related-skills: java-architect, database-optimizer, devops-engineer
---

# Spring Boot Engineer

## Core Workflow

1. **Analyze requirements** — Identify bounded contexts, APIs, data models, security needs
2. **Design architecture** — Monolith organized by bounded context. One package per feature, each split into `api` / `domain` / `application` / `infra` layers (see Package Structure below). Confirm the boundary map before coding
3. **Implement** — Create features with constructor injection and the layered structure (see Quick Start below)
4. **Secure** — Add Spring Security, OAuth2, method security, CORS configuration; verify security rules compile and pass tests. If compilation or tests fail: review error output, fix the failing rule or configuration, and re-run before proceeding
5. **Test** — Write unit, integration, and slice tests; run `./mvnw test` (or `./gradlew test`) and confirm all pass before proceeding. If tests fail: review the stack trace, isolate the failing assertion or component, fix the issue, and re-run the full suite
6. **Deploy** — Configure health checks and observability via Actuator; validate `/actuator/health` returns `UP`. If health is `DOWN`: check the `components` detail in the response, resolve the failing component (e.g., datasource, broker), and re-validate

## Package Structure

Monolith organized by **bounded context**: one package per feature, each split into
`api` / `domain` / `application` / `infra`. This is the canonical layout — all generated
code must follow it.

```
src/main/java/com/app/
├── config/                  # Global configs, beans, properties (incl. MessageSourceConfig)
├── shared/
│   ├── error/               # ErrorCode (central enum) + DomainException + GlobalExceptionHandler
│   └── specification/       # PredicateUtils — reusable JPA Criteria predicate builders
└── <feature>/
    ├── api/                 # HTTP edge layer
    │   ├── <Resource>Controller.java
    │   └── dto/                         # Input/output DTOs (records)
    │       ├── <Resource>Request.java   # entity built via constructor in the service
    │       └── <Resource>Response.java  # static factory: Response.from(entity)
    ├── domain/              # Core: model + rules + domain exceptions
    │   ├── model/                       # Entities and Value Objects
    │   │   └── <Resource>.java          # @Entity — invariants live HERE
    │   ├── service/                     # Domain services (rules crossing entities)
    │   │   └── <Rule>Service.java       # Optional — only when the rule does not fit the entity
    │   └── exception/                   # Domain exceptions
    │       ├── <Resource>NotFoundException.java
    │       └── <Resource>DuplicateException.java
    ├── application/         # Application services (orchestration between domain and infra)
    │   └── <Resource>Service.java
    └── infra/               # Repositories, external integrations
```

**Layer rules**: `api` never touches `infra` directly — it goes through `application`.
Business invariants live inside the `domain` entity; `application` only orchestrates.

## Reference Guide

Load detailed guidance based on context:

| Topic | Reference | Load When |
|-------|-----------|-----------|
| Web Layer | `references/web.md` | Controllers, REST APIs, validation, exception handling |
| Data Access | `references/data.md` | Spring Data JPA, repositories, transactions, projections, Specifications, PredicateUtils |
| Security | `references/security.md` | Spring Security 6, OAuth2, JWT, method security |
| Error Handling | `references/error-handling.md` | ErrorCode catalog, DomainException, GlobalExceptionHandler, i18n messages |
| Observability | `references/observability.md` | Structured logs, MDC/traceId, Actuator, metrics, Sentry |
| OpenAPI Contract | `references/openapi.md` | springdoc setup, controller/DTO annotations, error-contract docs, frontend handoff |
| Testing | `references/testing.md` | @SpringBootTest, MockMvc, Testcontainers, test slices |

## Quick Start — Minimal Working Structure

A feature is a bounded-context package split into `api` / `domain` / `application` / `infra`.
Each block below shows its target package. Use as copy-paste starting points.

### Entity — `domain/model`

```java
package com.app.product.domain.model;

@Entity
@Table(name = "products")
public class Product {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false)
    private BigDecimal price;

    // Invariants live HERE — guard them in the constructor / factory, not in the service.
    protected Product() {} // JPA

    public Product(String name, BigDecimal price) {
        if (price.signum() < 0) throw new ProductInvalidPriceException(price);
        this.name = name;
        this.price = price;
    }

    // getters (no public setters that break invariants)
}
```

### Repository — `infra`

```java
package com.app.product.infra;

public interface ProductRepository extends JpaRepository<Product, Long> {
    List<Product> findByNameContainingIgnoreCase(String name);
}
```

### Application Service (constructor injection) — `application`

```java
package com.app.product.application;

@Service
public class ProductService {
    private final ProductRepository repo;

    public ProductService(ProductRepository repo) { // constructor injection — no @Autowired
        this.repo = repo;
    }

    @Transactional(readOnly = true)
    public List<ProductResponse> search(String name) {
        return repo.findByNameContainingIgnoreCase(name).stream().map(ProductResponse::from).toList();
    }

    @Transactional
    public ProductResponse create(ProductRequest request) {
        var product = new Product(request.name(), request.price()); // invariants enforced in the entity
        return ProductResponse.from(repo.save(product));
    }
}
```

### REST Controller — `api`

```java
package com.app.product.api;

@RestController
@RequestMapping("/api/v1/products")
@Validated
public class ProductController {
    private final ProductService service;

    public ProductController(ProductService service) {
        this.service = service;
    }

    @GetMapping
    public List<ProductResponse> search(@RequestParam(defaultValue = "") String name) {
        return service.search(name);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ProductResponse create(@Valid @RequestBody ProductRequest request) {
        return service.create(request);
    }
}
```

### DTOs (records) — `api/dto`

Map Entity → DTO with a **static factory** on the response record. No mapper library, no
builder — the record's canonical constructor is the builder. Build the entity from the
request via its invariant-enforcing constructor (in the service).

```java
package com.app.product.api.dto;

// Custom validation messages inline (or via a messageKey resolved by MessageSource).
public record ProductRequest(
    @NotBlank(message = "Product name is required") String name,
    @NotNull @DecimalMin(value = "0.0", message = "Price must be zero or positive") BigDecimal price
) {}

public record ProductResponse(Long id, String name, BigDecimal price) {
    public static ProductResponse from(Product p) {
        return new ProductResponse(p.getId(), p.getName(), p.getPrice());
    }
}
```

> **When to switch to MapStruct**: stay with static factories by default. Adopt MapStruct
> (`@Mapper`, `componentModel = "spring"`) only when mapping boilerplate hurts — e.g. >3 DTOs
> per feature, deeply nested objects, or many repetitive fields. The controller/service edge
> does not change, so it is a painless later upgrade.

### Error Handling

Do **not** hand-roll a per-feature handler. The central `@RestControllerAdvice`
(`shared/error/GlobalExceptionHandler`) resolves messages via `MessageSource` and
translates `DomainException` → `ProblemDetail`. Throw a domain exception that carries an
`ErrorCode`; the handler does the rest. See `references/error-handling.md`.

```java
package com.app.product.domain.exception;

public class ProductInvalidPriceException extends DomainException {
    public ProductInvalidPriceException(BigDecimal price) {
        super(ErrorCode.PRODUCT_INVALID_PRICE, price);
    }
}
```

### Test Slice

```java
@WebMvcTest(ProductController.class)
class ProductControllerTest {
    @Autowired MockMvc mockMvc;
    @MockBean ProductService service;

    @Test
    void createProduct_validRequest_returns201() throws Exception {
        when(service.create(any())).thenReturn(new ProductResponse(1L, "Widget", BigDecimal.TEN));

        mockMvc.perform(post("/api/v1/products")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""{"name":"Widget","price":10.0}"""))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.name").value("Widget"));
    }
}
```

## Constraints

### MUST DO

| Rule | Correct Pattern |
|------|----------------|
| Constructor injection | `public MyService(Dep dep) { this.dep = dep; }` |
| Validate API input | `@Valid @RequestBody MyRequest req` on every mutating endpoint |
| Type-safe config | `@ConfigurationProperties(prefix = "app")` bound to a record/class |
| Appropriate stereotype | `@Service` for business logic, `@Repository` for data, `@RestController` for HTTP |
| Transaction scope | `@Transactional` on multi-step writes; `@Transactional(readOnly = true)` on reads |
| Bounded-context layers | Keep each feature in `api`/`domain`/`application`/`infra`; `api` reaches data only through `application` |
| Domain invariants | Enforce business rules inside the `domain` entity (constructor/factory), not in the service |
| Standard errors | Throw a `DomainException` carrying an `ErrorCode`; the central `GlobalExceptionHandler` maps it to `ProblemDetail` (see `references/error-handling.md`) |
| Externalize messages | Error/validation messages live in `messages*.properties` or inline on the constraint (`@NotBlank(message = "...")`) — never hardcoded in the handler |
| HTTP status in ErrorCode | The HTTP status lives in the `ErrorCode`, not scattered across `@ResponseStatus` or `if`s in the handler |
| Externalize secrets | Use environment variables — never `application.properties`/`application.yml` |

### MUST NOT DO
- Use field injection (`@Autowired` on fields)
- Skip input validation on API endpoints
- Use `@Component` when `@Service`/`@Repository`/`@Controller` applies
- Throw raw `RuntimeException("...")` — always a `DomainException` + `ErrorCode`
- Let `api` call `infra`/repositories directly, bypassing `application`
- Hardcode error messages in Java code instead of `messages*.properties`
- Store secrets or credentials in `application.properties`/`application.yml`
- Hardcode URLs, credentials, or environment-specific values
- Use deprecated Spring Boot 2.x patterns (e.g., `WebSecurityConfigurerAdapter`)

[Documentation](https://jeffallan.github.io/claude-skills/skills/backend/spring-boot-engineer/)
