# Convenções de Código

## Nomenclatura geral

- Idioma do código: **inglês** (identificadores, comentários, mensagens de log).
- Idioma da documentação de produto/spec: **português**.
- Identificadores descritivos. `data`, `info`, `result` sem qualificador são proibidos.

## Frontend (Angular)

### Monorepo vs app único

- **App único** (default da estrutura abaixo): use quando há uma aplicação Angular só.
- **Monorepo**: 2+ apps compartilhando código → estrutura `apps/` + `lib/{core,shared}`. Detalhes completos em [shared/angular-monorepo.md](../shared/angular-monorepo.md).

### Estrutura de pastas

```
src/app/
├── core/              # Singletons globais (auth, interceptors, error handler, stores globais)
│   └── stores/        # Stores compartilhados entre features (ex: sessão do usuário, tema)
├── shared/            # Componentes/pipes/diretivas reutilizáveis sem regra de negócio
└── features/
    └── <feature>/
        ├── pages/     # Componentes roteáveis (smart)
        ├── components/# Componentes de apresentação (dumb)
        ├── services/  # HTTP, integrações, lógica stateless
        ├── store/     # Signal store(s) específicos da feature
        ├── models/    # Interfaces/types (gerados do OpenAPI quando possível)
        └── <feature>.routes.ts
```

**Regra de decisão — onde colocar um store?**

- Estado **só** importa dentro da feature → `features/<feature>/store/`.
- Estado **compartilhado** por 2+ features (sessão, tema, permissões, notificações globais) → `core/stores/`.
- Não criar store global "por garantia" — só promova quando houver segunda feature consumindo.

### Nomes de arquivo

- Componentes: `user-profile.component.ts`
- Services: `user.service.ts`
- Stores (signal): `user.store.ts`
- Models: `user.model.ts` ou pasta `models/`
- Testes: `<arquivo>.spec.ts`

### Componentes

- Sempre `standalone: true`.
- Sempre `changeDetection: ChangeDetectionStrategy.OnPush`.
- Inputs com `input()` (signal-based) sempre que possível.
- Outputs com `output()`.
- Templates inline apenas para componentes < 15 linhas.

### Services

- Stateless por padrão. Estado vive em stores (signal store ou similar).
- `providedIn: 'root'` quando singleton; em escopo de feature use `providers` da rota.

### Observabilidade (Angular)

- **Nunca `console.*` direto em código de produção.** Sempre injetar `LoggerService` (em `core/logger/`).
- Erros não tratados sobem pro `GlobalErrorHandler` que envia ao Sentry em prod.
- HTTP requests carregam `traceparent` via interceptor pra correlation com backend.
- Padrão detalhado em [shared/observability.md](../shared/observability.md).

### Design responsivo (obrigatório)

> Princípio firmado em [constitution.md](constitution.md). Aqui ficam as regras práticas.

**Mobile-first**: CSS base é mobile (sem media query). Media queries **expandem** o layout pra telas maiores.

```scss
// ✅ certo — mobile-first
.card {
  padding: 1rem;
  flex-direction: column;

  @media (min-width: 768px) {
    padding: 2rem;
    flex-direction: row;
  }
}

// ❌ errado — desktop-first
.card {
  padding: 2rem;
  flex-direction: row;

  @media (max-width: 768px) {
    padding: 1rem;
    flex-direction: column;
  }
}
```

**Breakpoints padronizados** (definidos em `shared/styles/_breakpoints.scss` ou equivalente):

| Token | Valor | Uso |
|-------|-------|-----|
| `$bp-sm` | 360px | Mobile pequeno (alvo mínimo) |
| `$bp-md` | 768px | Tablet portrait |
| `$bp-lg` | 1024px | Tablet landscape / laptop pequeno |
| `$bp-xl` | 1440px | Desktop padrão |

**Regras**:

- Use **`clamp()`, `min()`, `max()`** antes de partir pra media query. Tipografia fluida (`font-size: clamp(1rem, 2.5vw, 1.5rem)`) elimina N breakpoints.
- **Container queries** (`@container`) > media queries quando o componente tem comportamento próprio independente do viewport.
- **Unidades relativas** (`rem`, `%`, `vh/vw`, `clamp`) > unidades absolutas (`px`). `px` só pra bordas finas e ícones.
- **Imagens responsivas** com `srcset`/`<picture>` + `loading="lazy"` em tudo que não é above-the-fold.
- **Touch targets ≥ 44px** em viewports mobile (botões, ícones clicáveis).
- **Grid/Flex** com `flex-wrap` e `gap` em vez de margens horizontais hard-coded.
- **Sem `overflow-x: hidden`** como solução pra layout que vaza — corrige o layout.

**Testar sempre nesses viewports** (Chrome DevTools): 360 / 768 / 1024 / 1440. Toda PR de UI deve incluir screenshot ou descrição confirmando os 4.

## Backend (Java/Spring)

### Estrutura de pastas

```
src/main/java/com/app/
├── config/                  # Configs globais, beans, properties (inclui MessageSourceConfig)
├── shared/
│   └── error/               # ErrorCode (enum central) + DomainException + GlobalExceptionHandler
└── <feature>/
    ├── api/                 # Camada de borda HTTP
    │   ├── <Recurso>Controller.java
    │   ├── dto/                        # DTOs de entrada e saída (records)
    │   │   ├── <Recurso>Request.java
    │   │   └── <Recurso>Response.java
    │   └── mapper/                     # Mappers MapStruct (Entity ↔ DTO)
    │       └── <Recurso>Mapper.java
    ├── domain/              # Núcleo: modelo + regras + exceptions de domínio
    │   ├── model/                       # Entities e Value Objects
    │   │   └── <Recurso>.java           # @Entity — invariantes vivem AQUI dentro
    │   ├── service/                     # Domain Services (regras que cruzam entidades)
    │   │   └── <Regra>Service.java      # Opcional — criar só quando a regra não cabe na entity
    │   └── exception/                   # Exceptions de domínio
    │       ├── <Recurso>NaoEncontradoException.java
    │       └── <Recurso>DuplicadoException.java
    ├── application/         # Application Services (orquestração entre domain e infra)
    │   └── <Recurso>Service.java
    └── infra/               # Repositories, integrações externas
```

**Regra de decisão — onde vai cada coisa?**

- **DTOs** (records `Request`/`Response`) ficam em `api/dto/`. Mesmo recurso simples começa com a subpasta — quando a feature crescer e tiver vários DTOs (filtros, projeções, listas), já está organizado.
- **Mappers** ficam em `api/mapper/` porque existem **só** pra servir a borda HTTP (converter entre DTOs e Entities). Mantém a dependência limpa: `api/` conhece `domain/`, mas `domain/` nunca conhece `api/`.
- **Exceptions de domínio** ficam em `domain/exception/` e **estendem `DomainException`** (em `shared/error/`). O `@RestControllerAdvice` global resolve mensagem via `MessageSource` e traduz pra HTTP. Detalhes em [shared/error-handling.md](../shared/error-handling.md).

### O que é "regra de negócio" e onde mora

Regra de negócio é **o que o sistema precisa cumprir pra estar consistente com o mundo do negócio**. Vive em 3 lugares:

| Tipo de regra | Onde fica | Exemplo |
|---------------|-----------|---------|
| **Invariante da entidade** — uma entidade sempre tem que cumprir | dentro da própria `model/<Entity>.java` (construtor, métodos) | "Fatura não pode ter valor negativo" |
| **Regra que cruza entidades** — envolve 2+ entidades, não pertence a nenhuma | `domain/service/<Regra>Service.java` (Domain Service) | "Cliente bloqueado não pode criar fatura" |
| **Falha de regra** — comunica violação ao chamador | `domain/exception/<X>Exception.java` | `FaturaPagaException`, `ClienteBloqueadoException` |

### O que NÃO é regra de negócio

| Coisa | Onde fica | Por que não é |
|-------|-----------|---------------|
| `@NotBlank`, `@Size`, `@Email` | `api/dto/` (Jakarta Validation) | Validação técnica do formato do input |
| `repository.save()` + `eventPublisher.publish()` | `application/<Recurso>Service.java` | Orquestração de infra |
| `Entity ↔ DTO` | `api/mapper/` | Tradução de fronteira |
| Ler `application.yml` | `config/` | Configuração técnica |

### Domain Service vs Application Service

| | Domain Service (`domain/service/`) | Application Service (`application/`) |
|--|------------------------------------|--------------------------------------|
| Função | Aplica regra que cruza entidades | Orquestra: carrega, chama domain, persiste, publica |
| Conhece `Repository`? | **Não** | Sim |
| Conhece HTTP/Kafka/etc? | **Não** | Sim |
| Lança exceptions de domínio? | Sim, é onde nascem | Não — só propaga |
| Quando criar? | Só se a regra não cabe numa entity sozinha | Sempre (é o entrypoint do Controller) |

**Fluxo típico**: `Controller → Application Service → (Repository.find + Domain Service / Entity + Repository.save) → Application Service propaga exception se houver`.

Exemplo:

```java
// application/FaturaService.java  (Application Service — orquestra)
@Service
@Transactional
public class FaturaService {

    private final FaturaRepository faturaRepo;
    private final ClienteRepository clienteRepo;
    private final FaturamentoPolicy faturamentoPolicy;  // domain service

    public Fatura criar(UUID clienteId, BigDecimal valor) {
        var cliente = clienteRepo.findById(clienteId)
            .orElseThrow(() -> new ClienteNaoEncontradoException(clienteId));

        var fatura = faturamentoPolicy.criarPara(cliente, valor);  // ← regra de domínio

        return faturaRepo.save(fatura);
    }
}

// domain/service/FaturamentoPolicy.java  (Domain Service — só regra, sem infra)
public class FaturamentoPolicy {
    public Fatura criarPara(Cliente cliente, BigDecimal valor) {
        if (cliente.estaBloqueado()) {
            throw new ClienteBloqueadoException(cliente.getId());
        }
        return new Fatura(cliente.getId(), valor);  // construtor valida invariante (valor > 0)
    }
}
```

### Nomes

- Controllers: `UserController` (sufixo `Controller`).
- Services: `UserService` (sufixo `Service`).
- Repositories: `UserRepository` (interface estendendo `JpaRepository`).
- DTOs: `UserRequest`, `UserResponse` (records).
- Mappers: `UserMapper` (interface MapStruct).
- Entities: `User` (sem sufixo).

### REST

- Plural nos paths: `/api/v1/users/{id}`.
- Status HTTP corretos: 201 Created com `Location`, 204 No Content em delete, 422 para validação de domínio, 400 para input inválido.
- Erros via `ProblemDetail` (RFC 7807).

### Observabilidade (Spring)

- **SLF4J** sempre com placeholders (`log.info("x={}", x)`), nunca concatenação.
- **MDC** populado com contexto relevante (`traceId`, `clienteId`, `userId`) via `try-with-resources`.
- **Profile dev**: Logback com pretty + cores. **Profile prod**: JSON via `logstash-logback-encoder`.
- **Sentry** recebe `WARN+` em prod; `INFO` vira breadcrumb.
- **Actuator** expõe `/health`, `/info`, `/metrics`, `/prometheus`.
- **Métricas custom** via `MeterRegistry`. Tags **nunca** com valores de alta cardinalidade (sem `clienteId`, `email`).
- Padrão detalhado em [shared/observability.md](../shared/observability.md).

## Commits

Convenção: **Conventional Commits**.

```
<tipo>(<escopo>): <descrição curta>

<corpo opcional explicando o porquê, não o quê>

Refs: SPEC-<id>
```

Tipos: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`, `build`.

## Branches

- `main` — sempre deployável.
- `feat/<spec-id>-<slug>` — feature nova.
- `fix/<issue>-<slug>` — bug.
- `chore/<slug>` — manutenção sem mudança de comportamento.

## Pull Requests

- Linkar a spec em `.spec/changes/` ou `.spec/archive/`.
- Checklist do [.spec/templates/review-checklist.md](../templates/review-checklist.md).
- Sem PR sem teste, exceto `chore` puro.
