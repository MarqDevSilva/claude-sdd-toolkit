# Monorepo Angular — Estrutura e Convenções

> Para workspaces com **2 ou mais apps Angular** compartilhando código.
> Usa **Angular CLI workspaces** (nativo, sem Nx). Layout: `apps/` + `lib/{core,shared}`.

## Quando usar

- 2+ apps que compartilham auth, stores globais, models de domínio, componentes de UI.
- Equipe quer evoluir o code compartilhado em PRs únicos, sem versionamento de pacote npm separado.

**Quando NÃO usar**: app único, ou apps com domínios completamente diferentes (separa em repos).

## Estrutura

```
workspace/
├── angular.json                    # registra todos apps e libs
├── package.json
├── tsconfig.json                   # define paths: @lib/core, @lib/shared
├── apps/
│   ├── app-a/                      # ng generate application app-a
│   │   └── src/app/
│   │       ├── core/               # singletons SÓ dessa app (rotas, layout)
│   │       ├── features/
│   │       └── app.config.ts
│   └── app-b/
│       └── src/app/
└── lib/
    ├── core/                       # ng generate library core
    │   ├── src/lib/
    │   │   ├── auth/               # AuthService, AuthGuard, AuthInterceptor
    │   │   ├── http/               # base HTTP config, error/retry interceptors
    │   │   ├── logger/             # LoggerService, GlobalErrorHandler
    │   │   ├── error/              # ErrorCode (enum espelho do back), tipos de erro
    │   │   ├── stores/             # session.store, user.store, theme.store
    │   │   ├── models/             # User, Session, Permission — cross-app
    │   │   ├── services/           # NotificationService, FeatureFlagService
    │   │   └── interceptors/       # traceId, auth, error
    │   └── public-api.ts           # única superfície pública
    └── shared/                     # ng generate library shared
        ├── src/lib/
        │   ├── components/         # Button, Card, Modal, FormField, Table
        │   ├── directives/         # ClickOutside, Autofocus
        │   ├── pipes/              # MaskPipe, DateRelativePipe
        │   ├── utils/              # funções puras (formatters, validators)
        │   └── styles/             # mixins SCSS, tokens, breakpoints
        └── public-api.ts
```

## Setup (Angular CLI)

```bash
# 1. Criar workspace sem app inicial
ng new <workspace-name> --create-application=false

cd <workspace-name>

# 2. Criar apps
ng generate application app-a --project-root=apps/app-a --standalone
ng generate application app-b --project-root=apps/app-b --standalone

# 3. Criar libs
ng generate library core    --project-root=lib/core
ng generate library shared  --project-root=lib/shared
```

`ng generate` cria as libs em `projects/` por padrão — `--project-root` redireciona pra estrutura desejada.

## `tsconfig.json` — paths

```json
{
  "compilerOptions": {
    "paths": {
      "@lib/core":   ["lib/core/src/public-api.ts"],
      "@lib/shared": ["lib/shared/src/public-api.ts"]
    }
  }
}
```

Imports nas apps:

```typescript
import { AuthService, SessionStore } from '@lib/core';
import { ButtonComponent, MaskPipe } from '@lib/shared';
```

**Nunca** importar via caminho relativo (`../../lib/core/src/...`) — quebra encapsulamento.

## O que vai em `core` vs `shared`

### `lib/core/`
**Tem regra de negócio cross-app ou injeta dependências de infra.**

| Vai em core | Por quê |
|-------------|---------|
| `AuthService`, `AuthGuard` | Autenticação é cross-app, tem state |
| `SessionStore`, `UserStore` | Estado compartilhado |
| `LoggerService`, `GlobalErrorHandler` | Singleton, injetam Sentry |
| `User`, `Session`, `Permission` (models) | Tipos de domínio cross-app |
| HTTP interceptors (auth, traceId, error) | Cross-app, dependem de `HttpClient` |
| `FeatureFlagService` | Lê config global |

### `lib/shared/`
**Componentes/pipes/diretivas dumb, utilitários puros. Zero regra de negócio.**

| Vai em shared | Por quê |
|---------------|---------|
| `ButtonComponent`, `CardComponent`, `ModalComponent` | UI pura, sem lógica de domínio |
| `MaskPipe`, `CurrencyBrPipe` | Transformação visual |
| `ClickOutsideDirective` | Comportamento UI genérico |
| Funções de formatação (`formatCpf`, `formatCurrency`) | Puras, sem injection |
| Mixins SCSS, tokens de design, breakpoints | Estilo compartilhado |

### O que NÃO vai em nenhuma das libs

- **Páginas/features de domínio específico** ficam no `app-X/src/app/features/`. Se duas apps precisam da mesma feature, abra uma **lib `feature-xxx`** dedicada (caso raro — discuta antes).
- **Componentes que dependem de Service de domínio** (smart components) — ficam na app.

## Regras de dependência

```
app-a → lib/core, lib/shared
app-b → lib/core, lib/shared
lib/core → lib/shared   ✓ (pode usar UI da shared)
lib/shared → lib/core   ✗ NUNCA (shared é a base, não conhece core)
lib/core → app-*        ✗ NUNCA
lib/shared → app-*      ✗ NUNCA
```

Lib **nunca** importa de app. App **sempre** importa de lib via `@lib/...`.

## `public-api.ts` — superfície pública

Cada lib expõe **só** o que é estável:

```typescript
// lib/core/src/public-api.ts
export * from './lib/auth/auth.service';
export * from './lib/auth/auth.guard';
export * from './lib/stores/session.store';
export * from './lib/models/user.model';
export * from './lib/logger/logger.service';
// ... só o que apps consomem
```

Internals (helpers, factories, classes base) **não** entram no `public-api.ts`. Se não está exportado, não é contrato — pode mudar livremente.

## Convenções de naming

- **Apps**: kebab-case sem prefixo (`app-a`, `dashboard`, `admin`).
- **Libs**: kebab-case sem prefixo (`core`, `shared`, `feature-checkout`).
- **Selectors de componentes shared**: prefixo do scope (`<ui-button>`, `<ui-card>`) pra evitar colisão com componentes de app.
- **Selectors de componentes de app**: prefixo da app (`<app-a-header>`, `<dashboard-sidebar>`).

## Stores globais — onde ficam

```
lib/core/src/lib/stores/
├── session.store.ts          # usuário logado, tokens, permissões
├── theme.store.ts            # tema dark/light, idioma
└── notification.store.ts     # toasts/alerts globais
```

Acessadas em todas apps via `inject(SessionStore)` depois de `import { SessionStore } from '@lib/core'`.

## Quando promover algo de app pra lib

Promove pra `lib/core` ou `lib/shared` quando:

1. **2+ apps já consomem** o mesmo código (mesmo que via cópia hoje).
2. **1 app consome e há intenção clara** de adicionar outra app que vai consumir.

**Não** promova "por garantia". Custo de extração depois é baixo — fica na app até realmente precisar.

## Testes em libs

- Cada lib tem sua suíte de testes (`ng test core`, `ng test shared`).
- Lib `shared` não pode quebrar `core` (não há dependência reversa).
- Mudança em lib roda testes de **todas apps** que dependem dela (no CI).

## Build e versionamento

- Apps são buildadas independentemente: `ng build app-a`, `ng build app-b`.
- Libs são **buildadas em conjunto** quando publicadas via `ng build core --watch` em dev, ou no CI antes do build das apps.
- Versionamento **único** do workspace (não publica libs em npm — consome via path interno).

## Anti-patterns a evitar

| Anti-pattern | Por que dói |
|--------------|-------------|
| Lib importando de app | Quebra inversão de dependência — apps são consumers |
| `shared` importando de `core` | Cria ciclo conceitual e dificulta extração futura |
| Tudo em `core` (inclusive UI) | Lib infla, recompilação lenta, lazy load impossível |
| Re-exportar tudo em `public-api.ts` | Vira big-ball-of-mud, contrato pouco intencional |
| Páginas/features inteiras em `core` | Domain leak — `core` deveria ser cross-app, não cross-feature |

## Checklist ao adicionar código compartilhado

- [ ] Decidi: vai em `core` (tem regra/state/infra) ou `shared` (UI/util puro)?
- [ ] Exportei só o necessário no `public-api.ts`
- [ ] Selector tem prefixo (`ui-...` em `shared`)
- [ ] Testes adicionados na própria lib
- [ ] Documento as 2+ apps que consomem (no PR ou em ADR se for decisão de arquitetura)
- [ ] Sem import relativo cruzando lib (sempre `@lib/...`)
