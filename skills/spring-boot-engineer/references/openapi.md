# OpenAPI Contract — springdoc (Backend Production Side)

> The backend is the **single source of truth** for the API contract. springdoc generates the
> OpenAPI spec from controllers + DTOs; the frontend consumes `/v3/api-docs` to generate a typed
> client. For the frontend sync/regeneration workflow, see the **`api-contract-sync`** skill —
> this reference only covers producing the spec.

## Dependency (Maven)

```xml
<dependency>
  <groupId>org.springdoc</groupId>
  <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>
  <version>2.6.0</version>
</dependency>
```

This exposes:
- `/v3/api-docs` — the OpenAPI JSON (what the frontend generator consumes)
- `/swagger-ui.html` — interactive UI (dev only)

## Configuration

### `application.yml`

```yaml
springdoc:
  api-docs:
    path: /v3/api-docs
  swagger-ui:
    path: /swagger-ui.html
    enabled: ${SWAGGER_UI_ENABLED:true}   # disable in prod
  default-produces-media-type: application/json
```

> Disable Swagger UI in production (`SWAGGER_UI_ENABLED=false`). Keep `/v3/api-docs` reachable
> from the CI/build that regenerates the frontend client (or export the spec to a file).

### `config/OpenApiConfig.java`

```java
package com.app.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {

    @Bean
    OpenAPI apiInfo(@Value("${APP_VERSION:dev}") String version) {
        return new OpenAPI().info(new Info()
            .title("App API")
            .version(version)
            .description("Contract is generated from controllers + DTOs. Do not edit by hand."));
    }
}
```

## Documenting controllers (minimal annotations)

Keep the controller readable — annotate intent, not every detail. springdoc already infers
types, status codes, and validation constraints from the method signature and bean-validation.

```java
package com.app.product.api;

@RestController
@RequestMapping("/api/v1/products")
@Tag(name = "Products", description = "Product catalog operations")
@Validated
public class ProductController {
    private final ProductService service;

    public ProductController(ProductService service) {
        this.service = service;
    }

    @Operation(summary = "Create a product")
    @ApiResponse(responseCode = "201", description = "Created")
    @ApiResponse(responseCode = "422", description = "Invalid price",
        content = @Content(schema = @Schema(implementation = ProblemDetail.class)))
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ProductResponse create(@Valid @RequestBody ProductRequest request) {
        return service.create(request);
    }
}
```

DTO records: `@Schema` only where the inferred contract needs clarification (examples, descriptions).
Bean-validation annotations (`@NotBlank`, `@DecimalMin`) already surface as constraints in the spec.

```java
public record ProductRequest(
    @Schema(example = "Wireless Mouse") @NotBlank String name,
    @Schema(example = "79.90") @NotNull @DecimalMin("0.0") BigDecimal price
) {}
```

## Documenting the error contract

The frontend branches on the stable `code` field (see `references/error-handling.md`), not on the
human-readable `detail`. Make that explicit in the spec so generated clients and consumers see it.

Errors are returned as RFC-7807 `ProblemDetail` with an extra `code` property:

```java
// reusable schema describing the error body
@Schema(name = "ApiError", description = "RFC-7807 problem detail with a stable error code")
public record ApiErrorSchema(
    @Schema(example = "PRODUCT_INVALID_PRICE") String code,
    @Schema(example = "422") int status,
    @Schema(example = "Product price must be positive. Received: -10.00.") String detail,
    @Schema(example = "PRODUCT_INVALID_PRICE") String title
) {}
```

Reference it on error responses (or globally via a `@ControllerAdvice`-level `@ApiResponse`):

```java
@ApiResponse(responseCode = "404", description = "Product not found",
    content = @Content(schema = @Schema(implementation = ApiErrorSchema.class)))
```

> Publishing the list of `ErrorCode` values lets the frontend mirror them as a typed enum. Keep
> the enum names stable — they are part of the contract, the messages are not.

## Versioning

- Version the API in the **path** (`/api/v1/...`), already the project convention.
- Set the spec `version` from `APP_VERSION` so each build stamps the contract.
- Commit the spec (or keep it exported) so contract diffs show up in PR review.

## Handoff to the frontend

Once `/v3/api-docs` is live (or exported to a file), the **`api-contract-sync`** skill reads the spec
and **builds/syncs the Angular domains** — for each tag a `model.ts` (interfaces 1:1 with the
schemas), plus a scaffolded `state.ts` + `service.ts` (over `HttpClient`) + `service.spec.ts`,
following the `angular-engineer` pattern. There is **no generated client**: the agent maps
tags→domains, schemas→interfaces, operations→service methods, and reports drift / breaking changes.
Keep the `ProblemDetails` error contract stable — the frontend mirrors it in `libs/shared/util`.

## Checklist when adding an endpoint

- [ ] `@Tag` on the controller, `@Operation(summary = ...)` on the method
- [ ] Non-2xx outcomes documented with `@ApiResponse` + the `ApiError` schema
- [ ] DTO fields have `@Schema(example = ...)` where the contract isn't obvious
- [ ] New `ErrorCode` values are reachable so the frontend can mirror them
- [ ] Spec regenerated and frontend domains synced via `api-contract-sync`
