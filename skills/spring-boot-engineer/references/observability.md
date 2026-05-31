# Observability — Logs, Metrics, Correlation (Backend)

> Strategy: **structured logs locally**, **Sentry in prod**, **Actuator/Micrometer for metrics**,
> **traceId** correlating requests end to end.

## Overview

```
┌────────────────────────────────────────────────────────────┐
│              Backend (Spring Boot)                         │
│   ┌────────────────────────────────────────────────────┐   │
│   │  Logback                                           │   │
│   │   ├─ dev: pretty console with colors + MDC inline  │   │
│   │   └─ prod: JSON (logstash-encoder)                 │   │
│   │  MDC: traceId, spanId, userId, requestId           │   │
│   │  Sentry Spring Boot starter → errors + breadcrumbs │   │
│   │  Actuator: /health, /info, /metrics, /prometheus   │   │
│   └────────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────┘
```

A client (web/mobile) is expected to send a W3C `traceparent` (or `X-Request-Id`) header;
the backend extracts it into the MDC so logs correlate across the request lifecycle.

## Dependencies (Maven)

```xml
<!-- Structured JSON logging -->
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

## `logback-spring.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>

  <!-- DEV: pretty console with colors and MDC -->
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

  <!-- PROD: structured JSON -->
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

    <!-- Sentry receives WARN+ -->
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

## `application.yml`

```yaml
spring:
  application:
    name: <app-name>

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

## How to log

Use SLF4J directly, **always** with placeholders (`{}`), never string concatenation.
Add context via MDC when relevant.

```java
@Service
@Slf4j
@RequiredArgsConstructor
public class ProductService {

    public Product create(Long customerId, BigDecimal price) {
        log.info("Creating product for customer={} price={}", customerId, price);

        try (var ignored = MDC.putCloseable("customerId", customerId.toString())) {
            // everything logged in here carries customerId in the MDC
            return ...;
        }
    }
}
```

## TraceId filter (correlation)

Spring Boot 3 + Micrometer Tracing handles this natively when you add
`micrometer-tracing-bridge-otel`. Without it, a manual filter:

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

## Log level conventions

| Level | When to use | Goes to Sentry? |
|-------|-------------|------------------|
| `DEBUG` | Useful detail for local debugging. Never in prod. | No |
| `INFO`  | Important flow milestone (created product X, authenticated user Y). | No (becomes a breadcrumb) |
| `WARN`  | Something odd but recoverable (retry, fallback, unexpected input). | Yes |
| `ERROR` | Real failure — exception, broken contract, corrupted data. | Yes |

## What to NEVER log

- **Passwords, tokens, API keys**.
- **Unnecessary PII**: full national IDs, full e-mail (mask it: `m***@gmail.com`), address, phone.
- **Full request/response payloads** with user data at INFO. At DEBUG, OK.
- **Full stack traces at INFO/WARN** — only at ERROR.

## Metrics (Spring Actuator)

### Exposed endpoints

| Endpoint | Use |
|----------|-----|
| `/actuator/health` | Liveness + readiness for the orchestrator (k8s, fly, etc.) |
| `/actuator/info` | Version, build time, git commit |
| `/actuator/metrics` | Lists available metrics |
| `/actuator/prometheus` | Scrape target for Prometheus/Grafana |

### Custom metrics

```java
@Service
@RequiredArgsConstructor
public class ProductService {

    private final MeterRegistry meter;

    public Product create(...) {
        var sample = Timer.start(meter);
        try {
            // ... logic
            meter.counter("product.created", "status", "success").increment();
            return product;
        } catch (Exception e) {
            meter.counter("product.created", "status", "error").increment();
            throw e;
        } finally {
            sample.stop(meter.timer("product.create.duration"));
        }
    }
}
```

### Naming conventions

- Metrics in `snake_case` or `dot.case` consistently (Micrometer normalizes). Project default: `dot.case` (`product.created`, `auth.login.duration`).
- Tags in `snake_case`: `status=success`, `customer_tier=premium`.
- Tags **never** with high-cardinality values (do not use `customerId` or `email` — it blows up Prometheus storage).

## Feature health check

For critical features, add a dedicated `HealthIndicator`:

```java
@Component
@RequiredArgsConstructor
public class ProductHealthIndicator implements HealthIndicator {

    private final ProductRepository repo;

    @Override
    public Health health() {
        try {
            return Health.up().withDetail("totalProducts", repo.count()).build();
        } catch (Exception e) {
            return Health.down(e).build();
        }
    }
}
```

It shows up automatically under `/actuator/health`.

## Checklist when adding a feature

- [ ] Service logs `INFO` at the start and end of the main operation
- [ ] Domain exceptions are thrown (the global handler takes care of `WARN`/`ERROR`)
- [ ] Custom metrics on critical operations (counter + timer)
- [ ] MDC populated with relevant context (customerId, etc.) via try-with-resources
- [ ] No PII in INFO logs

## Environment variables

| Variable | Used by | Default |
|----------|---------|---------|
| `SENTRY_DSN` | Backend | empty = Sentry disabled |
| `SPRING_PROFILES_ACTIVE` | Backend | `dev` |
| `APP_VERSION` | Backend (Sentry release) | `unknown` |
| `LOG_LEVEL` (custom) | Backend, overrides root level | `INFO` |
