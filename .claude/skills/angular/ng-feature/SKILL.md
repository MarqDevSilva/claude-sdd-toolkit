---
name: ng-feature
description: Scaffold completo de feature Angular — rotas, pasta pages/components/services/models, signal store inicial e arquivo de rotas pronto pra lazy-load.
---

# ng-feature

Use quando o usuário pedir pra **criar uma nova feature**, **scaffold completo de módulo**, **estrutura inicial de uma área** do app.

## Pré-requisitos

- Projeto Angular 18+ com roteamento standalone (`app.routes.ts` + `loadChildren` ou `loadComponent`).
- `.spec/memory/conventions.md` lida — segue a estrutura por feature.

## Detectar workspace: app único vs monorepo

Antes de gerar, **detectar** se é monorepo olhando `angular.json`:

- **App único**: um único projeto do tipo `application` → feature vai em `src/app/features/<feature>/`.
- **Monorepo**: múltiplos projetos (`apps/*` + `lib/core` + `lib/shared`) → perguntar **qual app** recebe a feature; vai em `apps/<app>/src/app/features/<feature>/`. Detalhes em [.spec/shared/angular-monorepo.md](../../../../.spec/shared/angular-monorepo.md).

Em ambos os casos a estrutura interna da feature é a mesma — só muda a raiz.

## O que faz

1. Pergunta:
   - Nome da feature em kebab-case (ex: `invoices`, `user-management`).
   - **Em monorepo**: em qual app vai (ex: `app-a`).
   - Páginas iniciais (ex: lista + detalhe; só lista; lista + edição).
   - Precisa de signal store? (default: sim para features com estado próprio).
2. Cria (raiz varia por workspace — ver acima):

```
<raiz>/features/<feature>/
├── pages/
│   ├── <feature>-list/         # se aplicável
│   │   ├── <feature>-list.component.{ts,html,scss,spec.ts}
│   ├── <feature>-detail/       # se aplicável
│   │   └── ...
├── components/                 # vazio inicialmente, pra dumb components
├── services/
│   └── <feature>.service.ts
├── models/
│   └── <feature>.model.ts      # interfaces locais (ou re-exportar do client gerado)
├── store/
│   └── <feature>.store.ts      # signal store local
└── <feature>.routes.ts
```

3. Conteúdo gerado:
   - `<feature>.routes.ts` exporta `Routes` com paths e `loadComponent` por página.
   - `<feature>.service.ts` injeta `HttpClient`, expõe métodos tipados.
   - `<feature>.store.ts` usa signals + `computed`; expõe ações como métodos.
   - Páginas vêm com header básico, OnPush, signals.
4. Sugere a linha pra adicionar em `app.routes.ts`:

```typescript
{
  path: '<feature>',
  loadChildren: () => import('./features/<feature>/<feature>.routes').then(m => m.<feature>Routes),
}
```

## Heurísticas

- Se a feature consome API REST, perguntar se já existe contrato em `.spec/templates/api-contract.template.md` ou OpenAPI. Se sim, sugerir regerar client TS em vez de criar interfaces à mão.
- Signal store por feature, não global. Estado global vive em `core/` (app único) ou `lib/core/stores/` (monorepo).
- Não criar páginas que o usuário não pediu — pergunte antes de gerar lista+detalhe+edição.
- **Imports compartilhados**: em monorepo, sempre `import { X } from '@lib/core'` / `'@lib/shared'`. Em app único, caminho relativo.
- **Páginas geradas devem ser mobile-first** (CSS base sem media query, breakpoints em `min-width`).

## Como invocar

```
/ng-feature
/ng-feature invoices com lista e detalhe
```

## Saída

- Árvore de arquivos criada.
- Snippet pra registrar em `app.routes.ts`.
- Próximos passos sugeridos (gerar client TS, criar primeiro componente dumb, etc).
