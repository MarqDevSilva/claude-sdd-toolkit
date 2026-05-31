# Error Handling Pattern — Spring Backend

> Strategy: **central error catalog + externalized messages + global handler**.
> Standardize today, translate tomorrow by swapping a `.properties` file.

## Overview

```
┌──────────────────────────────────────────────────────────────────┐
│  ErrorCode (central enum)                                         │
│    ├─ code (PRODUCT_INVALID_PRICE)                               │
│    ├─ messageKey (product.invalid-price)                         │
│    └─ HttpStatus (422)                                           │
│                                                                  │
│  DomainException (abstract base)                                 │
│    └─ carries ErrorCode + args (message parameters)             │
│                                                                  │
│  <Resource><Problem>Exception extends DomainException           │
│    └─ feature-specific, in <feature>/domain/exception/          │
│                                                                  │
│  GlobalExceptionHandler (@RestControllerAdvice)                 │
│    └─ resolves via MessageSource + Locale → ProblemDetail (RFC) │
│                                                                  │
│  messages.properties (default), messages_pt.properties, ...      │
└──────────────────────────────────────────────────────────────────┘
```

## Folder structure

```
src/main/java/com/app/
├── shared/
│   └── error/
│       ├── ErrorCode.java                       # Central enum of all codes
│       ├── DomainException.java                 # Abstract superclass
│       └── GlobalExceptionHandler.java          # @RestControllerAdvice
├── config/
│   └── MessageSourceConfig.java                 # MessageSource + LocaleResolver beans
└── <feature>/
    └── domain/
        └── exception/
            └── <Resource><Problem>Exception.java

src/main/resources/
├── messages.properties                          # default
└── messages_pt.properties                       # added when i18n is needed
```

## Implementation

### 1. ErrorCode — central catalog

```java
// shared/error/ErrorCode.java
package com.app.shared.error;

import org.springframework.http.HttpStatus;

public enum ErrorCode {

    // Customer
    CUSTOMER_NOT_FOUND("customer.not-found", HttpStatus.NOT_FOUND),
    CUSTOMER_BLOCKED("customer.blocked", HttpStatus.UNPROCESSABLE_ENTITY),

    // Product
    PRODUCT_NOT_FOUND("product.not-found", HttpStatus.NOT_FOUND),
    PRODUCT_INVALID_PRICE("product.invalid-price", HttpStatus.UNPROCESSABLE_ENTITY),
    PRODUCT_DUPLICATE("product.duplicate", HttpStatus.CONFLICT),

    // Generic (handler fallbacks)
    INPUT_INVALID("input.invalid", HttpStatus.BAD_REQUEST),
    UNEXPECTED_ERROR("error.unexpected", HttpStatus.INTERNAL_SERVER_ERROR);

    private final String messageKey;
    private final HttpStatus status;

    ErrorCode(String messageKey, HttpStatus status) {
        this.messageKey = messageKey;
        this.status = status;
    }

    public String messageKey() { return messageKey; }
    public HttpStatus status() { return status; }
}
```

### 2. DomainException — superclass

```java
// shared/error/DomainException.java
package com.app.shared.error;

public abstract class DomainException extends RuntimeException {

    private final ErrorCode code;
    private final transient Object[] args;

    protected DomainException(ErrorCode code, Object... args) {
        super(code.messageKey());   // fallback message = key, translated by the handler
        this.code = code;
        this.args = args;
    }

    public ErrorCode code() { return code; }
    public Object[] args() { return args; }
}
```

### 3. Feature exceptions — `<feature>/domain/exception/`

```java
// product/domain/exception/ProductNotFoundException.java
package com.app.product.domain.exception;

import com.app.shared.error.DomainException;
import com.app.shared.error.ErrorCode;

public class ProductNotFoundException extends DomainException {
    public ProductNotFoundException(Long id) {
        super(ErrorCode.PRODUCT_NOT_FOUND, id);
    }
}
```

```java
// product/domain/exception/ProductInvalidPriceException.java
public class ProductInvalidPriceException extends DomainException {
    public ProductInvalidPriceException(BigDecimal price) {
        super(ErrorCode.PRODUCT_INVALID_PRICE, price);
    }
}
```

### 4. Externalized messages

```properties
# src/main/resources/messages.properties (default)
customer.not-found=Customer {0} not found.
customer.blocked=Customer {0} is blocked and cannot perform this operation.
product.not-found=Product {0} not found.
product.invalid-price=Product price must be positive. Received: {0}.
product.duplicate=Product {0} already exists.
input.invalid=Invalid request: {0}.
error.unexpected=Unexpected error. Please try again later.
```

To add another language, create the parallel file:

```properties
# src/main/resources/messages_pt.properties
customer.not-found=Cliente {0} não encontrado.
customer.blocked=Cliente {0} está bloqueado e não pode realizar essa operação.
product.not-found=Produto {0} não encontrado.
product.invalid-price=O preço do produto deve ser positivo. Recebido: {0}.
product.duplicate=Produto {0} já existe.
input.invalid=Requisição inválida: {0}.
error.unexpected=Erro inesperado. Tente novamente mais tarde.
```

### 5. MessageSource configuration

```java
// config/MessageSourceConfig.java
package com.app.config;

import java.util.Locale;
import org.springframework.context.MessageSource;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.support.ReloadableResourceBundleMessageSource;
import org.springframework.web.servlet.LocaleResolver;
import org.springframework.web.servlet.i18n.AcceptHeaderLocaleResolver;

@Configuration
public class MessageSourceConfig {

    @Bean
    MessageSource messageSource() {
        var ms = new ReloadableResourceBundleMessageSource();
        ms.setBasename("classpath:messages");
        ms.setDefaultEncoding("UTF-8");
        ms.setUseCodeAsDefaultMessage(true);   // if the key is missing, return the key itself
        ms.setCacheSeconds(300);
        return ms;
    }

    @Bean
    LocaleResolver localeResolver() {
        var resolver = new AcceptHeaderLocaleResolver();
        resolver.setDefaultLocale(Locale.ENGLISH);   // set per project (e.g. Locale.of("pt", "BR"))
        return resolver;
    }
}
```

### 6. Global handler

The handler resolves domain exceptions, bean-validation failures, and the catch-all.
For validation it returns a **per-field error map** (`field → message`) so the frontend
can highlight each input.

```java
// shared/error/GlobalExceptionHandler.java
package com.app.shared.error;

import java.util.LinkedHashMap;
import java.util.Locale;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import org.springframework.context.MessageSource;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
@RequiredArgsConstructor
public class GlobalExceptionHandler {

    private final MessageSource messages;

    @ExceptionHandler(DomainException.class)
    ResponseEntity<ProblemDetail> handleDomain(DomainException ex, Locale locale) {
        var code = ex.code();
        var msg = messages.getMessage(code.messageKey(), ex.args(), locale);

        var problem = ProblemDetail.forStatusAndDetail(code.status(), msg);
        problem.setTitle(code.name());
        problem.setProperty("code", code.name());

        return ResponseEntity.status(code.status()).body(problem);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    ResponseEntity<ProblemDetail> handleValidation(MethodArgumentNotValidException ex, Locale locale) {
        // per-field map: { "name": "Product name is required", ... }
        Map<String, String> fieldErrors = new LinkedHashMap<>();
        ex.getBindingResult().getFieldErrors()
            .forEach(f -> fieldErrors.put(f.getField(), f.getDefaultMessage()));

        var msg = messages.getMessage(ErrorCode.INPUT_INVALID.messageKey(),
            new Object[] { String.join("; ", fieldErrors.values()) }, locale);

        var problem = ProblemDetail.forStatusAndDetail(ErrorCode.INPUT_INVALID.status(), msg);
        problem.setTitle(ErrorCode.INPUT_INVALID.name());
        problem.setProperty("code", ErrorCode.INPUT_INVALID.name());
        problem.setProperty("errors", fieldErrors);

        return ResponseEntity.status(ErrorCode.INPUT_INVALID.status()).body(problem);
    }

    @ExceptionHandler(Exception.class)
    ResponseEntity<ProblemDetail> handleUnexpected(Exception ex, Locale locale) {
        // log the stack trace here (never leak it to the client)
        var msg = messages.getMessage(ErrorCode.UNEXPECTED_ERROR.messageKey(), null, locale);
        var problem = ProblemDetail.forStatusAndDetail(ErrorCode.UNEXPECTED_ERROR.status(), msg);
        problem.setProperty("code", ErrorCode.UNEXPECTED_ERROR.name());
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(problem);
    }
}
```

### Validation messages — inline or by key

Bean-validation messages can be written **inline** on the constraint or **resolved by key**
from `messages*.properties` (wrap the key in `{}`):

```java
public record ProductRequest(
    @NotBlank(message = "Product name is required") String name,            // inline
    @NotNull @DecimalMin(value = "0.0", message = "{product.invalid-price}") BigDecimal price  // by key
) {}
```

## Example HTTP responses

Domain exception:

```http
HTTP/1.1 422 Unprocessable Entity
Content-Type: application/problem+json

{
  "type": "about:blank",
  "title": "PRODUCT_INVALID_PRICE",
  "status": 422,
  "detail": "Product price must be positive. Received: -10.00.",
  "code": "PRODUCT_INVALID_PRICE"
}
```

Validation error (per-field map):

```http
HTTP/1.1 400 Bad Request
Content-Type: application/problem+json

{
  "title": "INPUT_INVALID",
  "status": 400,
  "detail": "Invalid request: Product name is required",
  "code": "INPUT_INVALID",
  "errors": { "name": "Product name is required" }
}
```

The `code` field is the contract the frontend consumes to decide behavior (show a specific
modal, translate client-side, etc.). `detail` is for display only.

## Conventions

| Item | Standard |
|------|--------|
| Enum value name | `SCREAMING_SNAKE_CASE` (`PRODUCT_INVALID_PRICE`) |
| `messageKey` | `kebab-case` with `.` per domain (`product.invalid-price`) |
| Exception class | `<Resource><Problem>Exception` (`ProductDuplicateException`) |
| Message arguments | Positional `{0}`, `{1}` |
| HTTP status | Decided by the `ErrorCode`, **not** by the handler |

## Rules

1. **Every domain exception extends `DomainException`** and carries an `ErrorCode`. No loose `throw new RuntimeException("xxx")`.
2. **Messages never in Java code.** Only in `messages*.properties` (or inline on a bean-validation constraint).
3. **HTTP status lives in the `ErrorCode`**, not scattered across `@ResponseStatus` or `if`s in the handler.
4. **A new exception = 3 coordinated changes**:
   - New entry in the `ErrorCode` enum.
   - New key in `messages.properties` (and in other locales if present).
   - New `<X>Exception` class in the feature, extending `DomainException`.
5. **The client receives `code`** in the payload — that is the contract. The message is human-readable only and may change.

## Tests

```java
// Domain test (pure unit)
@Test
void productWithNegativePrice_throwsCorrectException() {
    assertThatThrownBy(() -> new Product("Widget", BigDecimal.valueOf(-1)))
        .isInstanceOf(ProductInvalidPriceException.class)
        .satisfies(ex -> {
            var dex = (ProductInvalidPriceException) ex;
            assertThat(dex.code()).isEqualTo(ErrorCode.PRODUCT_INVALID_PRICE);
            assertThat(dex.args()).containsExactly(BigDecimal.valueOf(-1));
        });
}
```

```java
// Handler test (WebMvc)
@Test
void post_422_whenProductPriceInvalid() throws Exception {
    when(service.create(any())).thenThrow(new ProductInvalidPriceException(BigDecimal.valueOf(-1)));

    mockMvc.perform(post("/api/v1/products").contentType(APPLICATION_JSON).content("..."))
        .andExpect(status().isUnprocessableEntity())
        .andExpect(jsonPath("$.code").value("PRODUCT_INVALID_PRICE"))
        .andExpect(jsonPath("$.detail").exists());
}
```

> **Note**: domain tests assert on **`code()`** and **`args()`**, not on the message.
> The message is a presentation detail and may change (even by translation).
