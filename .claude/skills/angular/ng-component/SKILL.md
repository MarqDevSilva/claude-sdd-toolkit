---
name: ng-component
description: Gera um componente Angular 18+ standalone com OnPush, signals, inputs/outputs tipados e teste inicial seguindo as convenções do projeto.
---

# ng-component

Use quando o usuário pedir pra **criar um componente Angular**, **gerar componente**, **scaffold de componente** ou similar.

## Pré-requisitos

- Workspace é um projeto Angular 18+.
- `.spec/memory/tech-stack.md` e `.spec/memory/conventions.md` estão disponíveis — **leia antes** de gerar código.

## Detectar workspace: app único vs monorepo

Olhar `angular.json` antes de gerar:

- **App único**: componente vai em `src/app/features/<feature>/...`.
- **Monorepo**: perguntar destino — pode ser `apps/<app>/src/app/features/<feature>/...` (componente de app) ou `lib/shared/src/lib/components/...` (componente UI reutilizável entre apps). Detalhes em [.spec/shared/angular-monorepo.md](../../../../.spec/shared/angular-monorepo.md).
  - **Em `lib/shared`**: selector com prefixo `ui-` (ex: `<ui-button>`); só dumb component (sem inject de service de domínio); exportar no `public-api.ts`.

## O que faz

1. Pergunta:
   - Nome do componente (kebab-case, sem sufixo `-component`).
   - Localização (feature da app, ou `lib/shared` em monorepo).
   - É smart (page) ou dumb (presentation)?
   - Inputs/outputs necessários (com tipos).
2. Cria arquivos no destino apropriado:
   - `<nome>.component.ts`
   - `<nome>.component.html`
   - `<nome>.component.scss`
   - `<nome>.component.spec.ts`
3. Componente:
   - `standalone: true`
   - `changeDetection: ChangeDetectionStrategy.OnPush`
   - Inputs com `input<T>()`, outputs com `output<T>()`
   - `inject(Service)` em vez de constructor injection
   - Sem decorator-less providers desnecessários
4. **SCSS gerado é mobile-first**:
   - Estilos base sem media query (assume viewport pequeno)
   - Breakpoints via `@use 'shared/styles/breakpoints'` quando expandir layout
   - Touch targets ≥ 44px em elementos clicáveis
   - Tipografia em `rem`/`clamp`, evitar `px` fixo

## Esqueleto gerado

```typescript
import { ChangeDetectionStrategy, Component, input, output } from '@angular/core';

@Component({
  selector: 'app-<nome>',
  standalone: true,
  templateUrl: './<nome>.component.html',
  styleUrl: './<nome>.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class <Nome>Component {
  readonly value = input.required<string>();
  readonly changed = output<string>();
}
```

## Teste gerado

- Usa `TestBed.configureTestingModule({ imports: [<Nome>Component] })` (standalone).
- Cobre criação + um input + um output.
- Usa `ComponentRef.setInput()` para setar inputs em teste.

## Heurísticas

- Componente **smart**: vai em `features/<feature>/pages/`, pode usar `inject()` de services e stores.
- Componente **dumb da app**: vai em `features/<feature>/components/`. **Não** injeta services de domínio — só recebe via inputs.
- Componente **dumb compartilhado entre apps (monorepo)**: vai em `lib/shared/src/lib/components/`, selector com prefixo `ui-`, exportado no `public-api.ts`.
- Sempre `OnPush`. Sem exceção.
- **Sempre mobile-first**: CSS base é mobile, media queries (`min-width`) expandem.
- Strings de UI externalizadas se i18n estiver no escopo do projeto.

## Como invocar

```
/ng-component
/ng-component user-card em features/users como dumb
```

## Saída

- Lista de arquivos criados com paths clicáveis.
- Sugestão de próximo passo (registrar rota se for page, ou exportar de barrel se for dumb).
