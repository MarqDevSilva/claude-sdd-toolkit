# Observabilidade — Logs, Métricas, Correlation

> Estratégia unificada front + back: **logs estruturados localmente**, **Sentry em prod**, **Actuator/Micrometer pra métricas**, **traceId correlacionando** os dois lados.

## Visão geral

```
┌──────────────────────────────────────────────────────────────────────────┐
│                     Frontend (Angular)                                   │
│   ┌─────────────────────────────────────────────────────────────────┐    │
│   │  LoggerService (inject)                                         │    │
│   │   ├─ dev: console pretty (colorido, com contexto)               │    │
│   │   └─ prod: enviar warn/error pro Sentry                         │    │
│   │                                                                 │    │
│   │  GlobalErrorHandler   → captura exceptions → Sentry             │    │
│   │  TraceIdInterceptor   → gera traceparent + envia no header HTTP │    │
│   └─────────────────────────────────────────────────────────────────┘    │
│                                ↓ HTTP (header: traceparent)              │
│   ┌─────────────────────────────────────────────────────────────────┐    │
│   │              Backend (Spring Boot)                              │    │
│   │   ┌────────────────────────────────────────────────────────┐    │    │
│   │   │  Logback                                               │    │    │
│   │   │   ├─ dev: pretty console com cores + MDC inline        │    │    │
│   │   │   └─ prod: JSON (logstash-encoder)                     │    │    │
│   │   │  MDC: traceId, spanId, userId, requestId               │    │    │
│   │   │  Sentry Spring Boot starter → erros + breadcrumbs      │    │    │
│   │   │  Actuator: /health, /info, /metrics, /prometheus       │    │    │
│   │   └────────────────────────────────────────────────────────┘    │    │
│   └─────────────────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────────────┘
```

## Backend (Spring Boot)

### Dependências (Maven)

```xml
<!-- Logging estruturado JSON -->
<dependency>
  <groupId>net.logstash.logback</groupId>
  <artifactId>logstash-logback-encoder</artifactId>
  <version>7.4</version>
</dependency>

<!-- Sentry -->
<dependency>
  <groupId>io.sentry</groupId>
  <artifactId>sentry-spring-boot-starter-jakarta</artifactId>
  <version>7.14.0</version>
</dependency>
<dependency>
  <groupId>io.sentry</groupId>
  <artifactId>sentry-logback</artifactId>
  <version>7.14.0</version>
</dependency>

<!-- Actuator + Prometheus -->
<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
<dependency>
  <groupId>io.micrometer</groupId>
  <artifactId>micrometer-registry-prometheus</artifactId>
</dependency>
```

### `logback-spring.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>

  <!-- DEV: console pretty com cores e MDC -->
  <springProfile name="dev | default">
    <appender name="CONSOLE" class="ch.qos.logback.core.ConsoleAppender">
      <encoder>
        <pattern>
          %d{HH:mm:ss.SSS} %highlight(%-5level) %cyan(%logger{20}) %magenta([traceId=%X{traceId:-},user=%X{userId:-}]) %msg %n
        </pattern>
      </encoder>
    </appender>

    <root level="INFO">
      <appender-ref ref="CONSOLE"/>
    </root>
    <logger name="com.app" level="DEBUG"/>
  </springProfile>

  <!-- PROD: JSON estruturado -->
  <springProfile name="prod">
    <appender name="JSON" class="ch.qos.logback.core.ConsoleAppender">
      <encoder class="net.logstash.logback.encoder.LogstashEncoder">
        <includeMdcKeyName>traceId</includeMdcKeyName>
        <includeMdcKeyName>spanId</includeMdcKeyName>
        <includeMdcKeyName>userId</includeMdcKeyName>
        <includeMdcKeyName>requestId</includeMdcKeyName>
        <customFields>{"app":"${spring.application.name}","env":"prod"}</customFields>
      </encoder>
    </appender>

    <!-- Sentry recebe WARN+ -->
    <appender name="SENTRY" class="io.sentry.logback.SentryAppender">
      <minimumEventLevel>WARN</minimumEventLevel>
      <minimumBreadcrumbLevel>INFO</minimumBreadcrumbLevel>
    </appender>

    <root level="INFO">
      <appender-ref ref="JSON"/>
      <appender-ref ref="SENTRY"/>
    </root>
  </springProfile>

</configuration>
```

### `application.yml`

```yaml
spring:
  application:
    name: <nome-do-app>

management:
  endpoints:
    web:
      exposure:
        include: health, info, metrics, prometheus
      base-path: /actuator
  endpoint:
    health:
      show-details: when-authorized
  metrics:
    tags:
      application: ${spring.application.name}

sentry:
  dsn: ${SENTRY_DSN:}
  environment: ${SPRING_PROFILES_ACTIVE:dev}
  traces-sample-rate: 0.1
  send-default-pii: false
  release: ${APP_VERSION:unknown}
```

### Como logar

Use SLF4J direto, **sempre** com placeholders (`{}`), nunca concatenação. Adicione contexto via MDC quando relevante.

```java
@Service
@Slf4j
@RequiredArgsConstructor
public class FaturaService {

    public Fatura criar(UUID clienteId, BigDecimal valor) {
        log.info("Criando fatura para cliente={} valor={}", clienteId, valor);

        try (var ignored = MDC.putCloseable("clienteId", clienteId.toString())) {
            // tudo logado aqui dentro vai ter clienteId no MDC
            return faturamentoPolicy.criarPara(...);
        }
    }
}
```

### Filtro de TraceId (correlation)

Spring Boot 3 + Micrometer Tracing já cuida disso nativamente quando você adiciona `micrometer-tracing-bridge-otel`. Se não usar, filtro manual:

```java
// shared/observability/TraceIdFilter.java
@Component
public class TraceIdFilter extends OncePerRequestFilter {

    @Override
    protected void doFilterInternal(HttpServletRequest req, HttpServletResponse res, FilterChain chain)
            throws ServletException, IOException {

        String traceId = extractFromTraceparent(req.getHeader("traceparent"))
            .orElse(req.getHeader("X-Request-Id"))
            .orElseGet(() -> UUID.randomUUID().toString().replace("-", ""));

        MDC.put("traceId", traceId);
        res.setHeader("X-Request-Id", traceId);
        try {
            chain.doFilter(req, res);
        } finally {
            MDC.clear();
        }
    }
}
```

## Frontend (Angular)

### Dependências

```json
{
  "dependencies": {
    "@sentry/angular": "^8.0.0"
  }
}
```

### `LoggerService` injetável

```typescript
// core/logger/logger.service.ts
import { Injectable, inject } from '@angular/core';
import { environment } from '../../../environments/environment';
import * as Sentry from '@sentry/angular';

type LogLevel = 'debug' | 'info' | 'warn' | 'error';

@Injectable({ providedIn: 'root' })
export class LoggerService {

  debug(message: string, context?: Record<string, unknown>) { this.log('debug', message, context); }
  info(message: string, context?: Record<string, unknown>) { this.log('info', message, context); }
  warn(message: string, context?: Record<string, unknown>) { this.log('warn', message, context); }
  error(message: string, error?: unknown, context?: Record<string, unknown>) {
    this.log('error', message, context);
    if (environment.production) {
      Sentry.captureException(error ?? new Error(message), { extra: context });
    }
  }

  private log(level: LogLevel, message: string, context?: Record<string, unknown>) {
    if (environment.production && level === 'debug') return;

    const styles: Record<LogLevel, string> = {
      debug: 'color: #888',
      info:  'color: #0af; font-weight: bold',
      warn:  'color: #fa0; font-weight: bold',
      error: 'color: #f33; font-weight: bold',
    };
    const ts = new Date().toISOString().slice(11, 23);
    const tag = `%c[${level.toUpperCase()}] ${ts}`;

    if (context) console[level === 'debug' ? 'log' : level](tag, styles[level], message, context);
    else         console[level === 'debug' ? 'log' : level](tag, styles[level], message);
  }
}
```

Uso:

```typescript
private readonly logger = inject(LoggerService);

this.logger.info('Carregando faturas', { clienteId });
this.logger.error('Falha ao carregar', err, { clienteId });
```

### Global error handler

```typescript
// core/logger/global-error.handler.ts
import { ErrorHandler, Injectable, inject } from '@angular/core';
import { LoggerService } from './logger.service';

@Injectable({ providedIn: 'root' })
export class GlobalErrorHandler implements ErrorHandler {
  private readonly logger = inject(LoggerService);

  handleError(error: unknown): void {
    this.logger.error('Erro não tratado', error);
  }
}
```

Registrar em `app.config.ts`:

```typescript
{ provide: ErrorHandler, useClass: GlobalErrorHandler }
```

### Interceptor de correlation

```typescript
// core/interceptors/trace-id.interceptor.ts
import { HttpInterceptorFn } from '@angular/common/http';

export const traceIdInterceptor: HttpInterceptorFn = (req, next) => {
  const traceId = crypto.randomUUID().replace(/-/g, '');
  const traceparent = `00-${traceId}${traceId.slice(0, 16)}-${traceId.slice(0, 16)}-01`;

  return next(req.clone({
    setHeaders: {
      traceparent,
      'X-Request-Id': traceId,
    },
  }));
};
```

Registrar:

```typescript
provideHttpClient(withInterceptors([traceIdInterceptor]))
```

### Sentry init (`main.ts`)

```typescript
import * as Sentry from '@sentry/angular';

Sentry.init({
  dsn: environment.sentryDsn,
  environment: environment.production ? 'prod' : 'dev',
  tracesSampleRate: 0.1,
  release: environment.version,
  integrations: [Sentry.browserTracingIntegration()],
});
```

## Convenções de log levels

| Nível | Quando usar | Vai pro Sentry? |
|-------|-------------|------------------|
| `DEBUG` | Detalhe útil pra debug local. Nunca em prod. | Não |
| `INFO`  | Marco importante do fluxo (criou fatura X, autenticou usuário Y). | Não (vira breadcrumb) |
| `WARN`  | Algo estranho mas recuperável (retry, fallback, input inesperado). | Sim |
| `ERROR` | Falha real — exception, contrato quebrado, dado corrompido. | Sim |

## O que NUNCA logar

- **Senhas, tokens, chaves de API**.
- **PII desnecessária**: CPF completo, e-mail completo (mascarar: `m***@gmail.com`), endereço, telefone.
- **Payloads completos de request/response** com dados de usuário em INFO. Em DEBUG, OK.
- **Stack trace inteiro em INFO/WARN** — só em ERROR.

## Métricas (Spring Actuator)

### Endpoints expostos

| Endpoint | Uso |
|----------|-----|
| `/actuator/health` | Liveness + readiness pro orquestrador (k8s, fly, etc.) |
| `/actuator/info` | Versão, build time, git commit |
| `/actuator/metrics` | Lista métricas disponíveis |
| `/actuator/prometheus` | Scrape pro Prometheus/Grafana |

### Métricas custom

```java
@Service
@RequiredArgsConstructor
public class FaturaService {

    private final MeterRegistry meter;

    public Fatura criar(...) {
        var sample = Timer.start(meter);
        try {
            // ... lógica
            meter.counter("fatura.criada", "status", "sucesso").increment();
            return fatura;
        } catch (Exception e) {
            meter.counter("fatura.criada", "status", "erro").increment();
            throw e;
        } finally {
            sample.stop(meter.timer("fatura.criar.duracao"));
        }
    }
}
```

### Convenções de nomes

- Métricas em `snake_case` ou `dot.case` consistente (Micrometer normaliza). Padrão do projeto: `dot.case` (`fatura.criada`, `auth.login.duracao`).
- Tags em `snake_case`: `status=sucesso`, `cliente_tipo=premium`.
- Tags **nunca** com valores de alta cardinalidade (não usar `clienteId` ou `email` — explode o storage do Prometheus).

## Correlation front ↔ back ↔ Sentry

1. **Front gera** `traceparent` (W3C) no interceptor.
2. **Front loga** `traceId` em todo log local + envia ao Sentry como tag.
3. **Back recebe** o header, extrai pro MDC, loga em todo registro.
4. **Sentry** dos dois lados é o mesmo projeto (ou projetos linkados) — busca por `traceId` cruza front e back.

Resultado: dado um erro no Sentry, em 2 cliques você vê o que o usuário fez no front + o que o backend processou.

## Health check da feature

Para features críticas, adicionar `HealthIndicator` próprio:

```java
@Component
@RequiredArgsConstructor
public class FaturaHealthIndicator implements HealthIndicator {

    private final FaturaRepository repo;

    @Override
    public Health health() {
        try {
            repo.count();   // ping ao banco
            return Health.up().withDetail("totalFaturas", repo.count()).build();
        } catch (Exception e) {
            return Health.down(e).build();
        }
    }
}
```

Aparece automaticamente em `/actuator/health`.

## Checklist ao adicionar uma feature

- [ ] Service loga `INFO` no início e fim da operação principal
- [ ] Exceptions de domínio são lançadas (handler global cuida do `WARN`/`ERROR`)
- [ ] Métricas custom em operações críticas (counter + timer)
- [ ] MDC populado com contexto relevante (clienteId, etc.) via `try-with-resources`
- [ ] Front usa `LoggerService.error(...)` em vez de `console.error`
- [ ] Sem PII em log INFO

## Variáveis de ambiente

| Variável | Quem usa | Default |
|----------|----------|---------|
| `SENTRY_DSN` | Back + front | vazio = Sentry desligado |
| `SPRING_PROFILES_ACTIVE` | Back | `dev` |
| `APP_VERSION` | Back (release no Sentry) | `unknown` |
| `LOG_LEVEL` (custom) | Back, sobrescreve nível root | `INFO` |
