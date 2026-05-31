# Stack Técnica

> Preencha com versões reais do projeto destino. Os valores abaixo são defaults sugeridos.

## Frontend — Angular

| Item | Versão / Escolha |
|------|------------------|
| Angular | 18+ (standalone, signals, novo control flow) |
| Workspace | App único OU monorepo (`apps/` + `lib/{core,shared}`) com Angular CLI workspaces |
| Gerenciador de pacotes | pnpm / npm |
| Estilos | SCSS + variáveis de tema |
| State | Signals (preferencial), NgRx Signal Store para estado global |
| HTTP | HttpClient + interceptors tipados |
| Forms | Reactive Forms tipados |
| Testes unitários | Jest (preferencial) ou Karma+Jasmine |
| E2E | Playwright |
| Lint/Format | ESLint + Prettier |
| Build | Esbuild (default do Angular CLI 18+) |
| Logger | `LoggerService` próprio (env-aware) — dev = console pretty, prod = Sentry |
| Error tracking | Sentry (`@sentry/angular`) |

### Convenções Angular

- **Componentes standalone** por padrão. NgModules apenas em casos legados.
- **Change detection** = `OnPush` em todos componentes.
- **Signals** para estado local; `computed()` para derivados; `effect()` apenas em side-effects de UI.
- **Inject function** (`inject(Service)`) em vez de constructor injection nos casos novos.
- **Mobile-first responsivo** em todo componente. Detalhes em [conventions.md](conventions.md#design-responsivo-obrigatório).
- **Monorepo**: estrutura `apps/` + `lib/{core,shared}` via Angular CLI workspaces. Guia em [shared/angular-monorepo.md](../shared/angular-monorepo.md).

## Backend — Java / Spring

| Item | Versão / Escolha |
|------|------------------|
| Java | 21 (LTS) |
| Spring Boot | 3.3+ |
| Build | Maven ou Gradle (Kotlin DSL) |
| Persistência | Spring Data JPA + Hibernate |
| Banco | PostgreSQL |
| Migrations | Flyway |
| Documentação API | springdoc-openapi (OpenAPI 3) |
| Testes | JUnit 5 + AssertJ + Testcontainers |
| Mappers | MapStruct |
| Validação | Jakarta Validation (`@Valid`) |
| Lint/Format | Spotless + Checkstyle |
| Logs | Logback (dev = pretty + cores; prod = JSON via logstash-encoder) |
| Error tracking | Sentry (sentry-spring-boot-starter-jakarta) |
| Métricas & Health | Spring Boot Actuator + Micrometer + Prometheus |

### Convenções Spring

- **Pacotes por feature**, não por camada técnica. Ex: `com.app.invoice.{api,domain,infra}`.
- **DTOs distintos** de Entities. Mappers via MapStruct.
- **Exceptions de domínio** + `@RestControllerAdvice` global.
- **Records** para DTOs imutáveis.
- **Testes**: slice tests (`@WebMvcTest`, `@DataJpaTest`) primeiro; integração com `@SpringBootTest` + Testcontainers só onde necessário.

## Integração Front ↔ Back

- Contrato API documentado em OpenAPI (gerado pelo Spring com springdoc).
- Cliente Angular gerado a partir do spec OpenAPI (openapi-generator) — não escrevemos interfaces TS à mão.
- Versionamento de API via prefixo de path: `/api/v1/...`.
