# Padrão de Tratamento de Erros — Backend Spring

> Estratégia: **catálogo central de erros + mensagens externalizadas + handler global**.
> Padroniza hoje, traduz amanhã trocando arquivo `.properties`.

## Visão geral

```
┌──────────────────────────────────────────────────────────────────┐
│  ErrorCode (enum central)                                        │
│    ├─ código (FATURA_VALOR_INVALIDO)                             │
│    ├─ messageKey (fatura.valor-invalido)                         │
│    └─ HttpStatus (422)                                           │
│                                                                  │
│  DomainException (base abstract)                                 │
│    └─ carrega ErrorCode + args (parâmetros da mensagem)          │
│                                                                  │
│  <Recurso>SuaException extends DomainException                   │
│    └─ específica da feature, em <feature>/domain/exception/      │
│                                                                  │
│  GlobalExceptionHandler (@RestControllerAdvice)                  │
│    └─ resolve via MessageSource + Locale → ProblemDetail (RFC)   │
│                                                                  │
│  messages.properties (pt-BR default), messages_en.properties...  │
└──────────────────────────────────────────────────────────────────┘
```

## Estrutura de pastas

```
src/main/java/com/app/
├── shared/
│   └── error/
│       ├── ErrorCode.java                       # Enum central de todos os códigos
│       ├── DomainException.java                 # Superclasse abstract
│       └── GlobalExceptionHandler.java          # @RestControllerAdvice
├── config/
│   └── MessageSourceConfig.java                 # Beans MessageSource + LocaleResolver
└── <feature>/
    └── domain/
        └── exception/
            └── <Recurso><Problema>Exception.java

src/main/resources/
├── messages.properties                          # default (pt-BR)
└── messages_en.properties                       # adicionado quando i18n entrar
```

## Implementação

### 1. ErrorCode — catálogo central

```java
// shared/error/ErrorCode.java
package com.app.shared.error;

import org.springframework.http.HttpStatus;

public enum ErrorCode {

    // Cliente
    CLIENTE_NAO_ENCONTRADO("cliente.nao-encontrado", HttpStatus.NOT_FOUND),
    CLIENTE_BLOQUEADO("cliente.bloqueado", HttpStatus.UNPROCESSABLE_ENTITY),

    // Fatura
    FATURA_NAO_ENCONTRADA("fatura.nao-encontrada", HttpStatus.NOT_FOUND),
    FATURA_VALOR_INVALIDO("fatura.valor-invalido", HttpStatus.UNPROCESSABLE_ENTITY),
    FATURA_JA_PAGA("fatura.ja-paga", HttpStatus.UNPROCESSABLE_ENTITY),

    // Genéricos (fallback do handler)
    INPUT_INVALIDO("input.invalido", HttpStatus.BAD_REQUEST),
    ERRO_INESPERADO("erro.inesperado", HttpStatus.INTERNAL_SERVER_ERROR);

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

### 2. DomainException — superclasse

```java
// shared/error/DomainException.java
package com.app.shared.error;

public abstract class DomainException extends RuntimeException {

    private final ErrorCode code;
    private final transient Object[] args;

    protected DomainException(ErrorCode code, Object... args) {
        super(code.messageKey());   // fallback message = chave, traduzido pelo handler
        this.code = code;
        this.args = args;
    }

    public ErrorCode code() { return code; }
    public Object[] args() { return args; }
}
```

### 3. Exceptions de feature

```java
// <feature>/domain/exception/ClienteNaoEncontradoException.java
package com.app.cliente.domain.exception;

import com.app.shared.error.DomainException;
import com.app.shared.error.ErrorCode;
import java.util.UUID;

public class ClienteNaoEncontradoException extends DomainException {
    public ClienteNaoEncontradoException(UUID id) {
        super(ErrorCode.CLIENTE_NAO_ENCONTRADO, id);
    }
}
```

```java
// <feature>/domain/exception/FaturaValorInvalidoException.java
public class FaturaValorInvalidoException extends DomainException {
    public FaturaValorInvalidoException(BigDecimal valor) {
        super(ErrorCode.FATURA_VALOR_INVALIDO, valor);
    }
}
```

### 4. Mensagens externalizadas

```properties
# src/main/resources/messages.properties (default = pt-BR)
cliente.nao-encontrado=Cliente {0} não encontrado.
cliente.bloqueado=Cliente {0} está bloqueado e não pode realizar essa operação.
fatura.nao-encontrada=Fatura {0} não encontrada.
fatura.valor-invalido=Valor da fatura deve ser positivo. Recebido: {0}.
fatura.ja-paga=Fatura {0} já foi paga e não pode ser modificada.
input.invalido=Requisição inválida: {0}.
erro.inesperado=Erro inesperado. Tente novamente mais tarde.
```

Quando adicionar inglês, basta criar o arquivo paralelo:

```properties
# src/main/resources/messages_en.properties
cliente.nao-encontrado=Customer {0} not found.
cliente.bloqueado=Customer {0} is blocked and cannot perform this operation.
fatura.nao-encontrada=Invoice {0} not found.
fatura.valor-invalido=Invoice value must be positive. Received: {0}.
fatura.ja-paga=Invoice {0} has already been paid.
input.invalido=Invalid request: {0}.
erro.inesperado=Unexpected error. Please try again later.
```

### 5. Configuração do MessageSource

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
        ms.setUseCodeAsDefaultMessage(true);   // se não achar a chave, devolve a própria chave
        ms.setCacheSeconds(300);
        return ms;
    }

    @Bean
    LocaleResolver localeResolver() {
        var resolver = new AcceptHeaderLocaleResolver();
        resolver.setDefaultLocale(new Locale("pt", "BR"));
        return resolver;
    }
}
```

### 6. Handler global

```java
// shared/error/GlobalExceptionHandler.java
package com.app.shared.error;

import java.util.Locale;
import lombok.RequiredArgsConstructor;
import org.springframework.context.MessageSource;
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
        problem.setProperty("codigo", code.name());

        return ResponseEntity.status(code.status()).body(problem);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    ResponseEntity<ProblemDetail> handleValidation(MethodArgumentNotValidException ex, Locale locale) {
        var detalhes = ex.getBindingResult().getFieldErrors().stream()
            .map(f -> f.getField() + ": " + f.getDefaultMessage())
            .toList();

        var msg = messages.getMessage(ErrorCode.INPUT_INVALIDO.messageKey(),
            new Object[] { String.join("; ", detalhes) }, locale);

        var problem = ProblemDetail.forStatusAndDetail(ErrorCode.INPUT_INVALIDO.status(), msg);
        problem.setProperty("codigo", ErrorCode.INPUT_INVALIDO.name());
        problem.setProperty("erros", detalhes);

        return ResponseEntity.status(ErrorCode.INPUT_INVALIDO.status()).body(problem);
    }

    @ExceptionHandler(Exception.class)
    ResponseEntity<ProblemDetail> handleUnexpected(Exception ex, Locale locale) {
        // logar o stack trace aqui (não vazar pro client)
        var msg = messages.getMessage(ErrorCode.ERRO_INESPERADO.messageKey(), null, locale);
        var problem = ProblemDetail.forStatusAndDetail(ErrorCode.ERRO_INESPERADO.status(), msg);
        problem.setProperty("codigo", ErrorCode.ERRO_INESPERADO.name());
        return ResponseEntity.internalServerError().body(problem);
    }
}
```

## Exemplo de resposta HTTP

```http
HTTP/1.1 422 Unprocessable Entity
Content-Type: application/problem+json

{
  "type": "about:blank",
  "title": "FATURA_VALOR_INVALIDO",
  "status": 422,
  "detail": "Valor da fatura deve ser positivo. Recebido: -10.00.",
  "codigo": "FATURA_VALOR_INVALIDO"
}
```

O campo `codigo` é o que o frontend consome pra decidir comportamento (mostrar modal específico, traduzir no client, etc.). `detail` é só pra exibição.

## Convenções

| Item | Padrão |
|------|--------|
| Nome do enum value | `SCREAMING_SNAKE_CASE` (`FATURA_VALOR_INVALIDO`) |
| `messageKey` | `kebab-case` com `.` por domínio (`fatura.valor-invalido`) |
| Classe da exception | `<Recurso><Problema>Exception` (`FaturaJaPagaException`) |
| Argumentos da mensagem | Posicionais `{0}`, `{1}` |
| Status HTTP | Decidido pelo `ErrorCode`, **não** pelo handler |

## Regras

1. **Toda exception de domínio estende `DomainException`** e carrega um `ErrorCode`. Sem `throw new RuntimeException("xxx")` solto.
2. **Mensagens nunca em código Java.** Só em `messages*.properties`.
3. **Status HTTP mora no `ErrorCode`**, não espalhado em `@ResponseStatus` ou `if`s do handler.
4. **Exception nova = 3 mudanças coordenadas**:
   - Entrada nova no enum `ErrorCode`.
   - Chave nova em `messages.properties` (e em outros locales se já houver).
   - Classe `<X>Exception` na feature, estendendo `DomainException`.
5. **Cliente recebe `codigo`** no payload — esse é o contrato. Mensagem é só human-readable, pode mudar.

## Testes

```java
// Domain test (unit puro)
@Test
void faturaComValorNegativo_lancaExcecaoCorreta() {
    assertThatThrownBy(() -> new Fatura(BigDecimal.valueOf(-1)))
        .isInstanceOf(FaturaValorInvalidoException.class)
        .satisfies(ex -> {
            var dex = (FaturaValorInvalidoException) ex;
            assertThat(dex.code()).isEqualTo(ErrorCode.FATURA_VALOR_INVALIDO);
            assertThat(dex.args()).containsExactly(BigDecimal.valueOf(-1));
        });
}
```

```java
// Handler test (WebMvc)
@Test
void post_422_quandoFaturaValorInvalido() throws Exception {
    when(service.criar(any())).thenThrow(new FaturaValorInvalidoException(BigDecimal.valueOf(-1)));

    mockMvc.perform(post("/api/v1/faturas").contentType(APPLICATION_JSON).content("..."))
        .andExpect(status().isUnprocessableEntity())
        .andExpect(jsonPath("$.codigo").value("FATURA_VALOR_INVALIDO"))
        .andExpect(jsonPath("$.detail").exists());
}
```

> **Note**: teste de domínio assert no **`code()`** e **`args()`**, não na mensagem. Mensagem é detalhe de apresentação, pode mudar (até por tradução).

## Frontend — consumir esse contrato

No Angular, o interceptor lê `error.codigo` (não `error.detail`) pra decidir UX:

```typescript
// core/interceptors/error.interceptor.ts (esboço)
if (error.error?.codigo === 'CLIENTE_BLOQUEADO') {
  this.dialog.open(ClienteBloqueadoDialog, { data: error.error.detail });
} else {
  this.toast.error(error.error?.detail ?? 'Erro inesperado');
}
```

Lista de códigos pode ser gerada no front a partir do OpenAPI (quando documentada lá) ou mantida manualmente como enum espelho — escolha por projeto.
