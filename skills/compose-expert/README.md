# compose-expert

> Padrões avançados de Compose Multiplatform para composables compartilhados.

Expert de UI visual em Compose. Cobre criação e refatoração de componentes compartilhados, state management (`remember`, `derivedStateOf`, `produceState`), otimização de recomposição (uso visual de `@Stable`/`@Immutable`), theming Material3, ícones `ImageVector` customizados e a decisão entre compartilhar UI em `commonMain` ou manter platform-specific.

## Quando usar

- Criar ou refatorar componentes de UI compartilhados.
- Decidir entre compartilhar UI em `commonMain` ou manter platform-specific.
- State management visual (`remember`, `derivedStateOf`, `produceState`).
- Otimizar recomposição, theming Material3 ou ícones `ImageVector`.

## Conteúdo

- `SKILL.md` — filosofia de compartilhamento e padrões de UI.
- `references/icon-assets.md` — ícones `ImageVector` customizados.
- `references/rich-text-parsing.md` — parsing de rich text.
- `references/shared-composables-catalog.md` — catálogo de composables compartilhados.
- `references/state-patterns.md` — padrões de estado em Compose.
- `scripts/find-composables.sh` — localiza composables no projeto.

## Relação com outras skills

Expert de baixo nível invocado pela `kmp-architect`; delega navegação para `android-expert` e aspectos de linguagem de estado para `kotlin-expert`. As convenções de stack do projeto (Android com Jetpack Compose + Navigation Compose, iOS com SwiftUI) vêm da `kmp-architect`, que documenta o override da stack Amethyst citada aqui (Desktop target) — aplique os padrões de Compose, não as escolhas específicas do Amethyst.
