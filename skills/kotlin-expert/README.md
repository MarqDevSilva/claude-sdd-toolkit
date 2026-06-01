# kotlin-expert

> Padrões avançados de Kotlin: Flow state, sealed hierarchies, imutabilidade, DSLs e inline.

Expert de idiomas Kotlin para estado e tipos. Cobre gerenciamento de estado com hot flows (`StateFlow`/`SharedFlow`/`MutableStateFlow`), hierarquias `sealed class` vs `sealed interface`, imutabilidade (`@Immutable`, data classes), DSL builders com lambda receivers e funções `inline`/`reified`.

## Quando usar

- Gerenciamento de estado com `StateFlow`/`SharedFlow`/`MutableStateFlow`.
- Modelar variantes com `sealed class` ou `sealed interface`.
- Aplicar `@Immutable` para estabilidade no Compose.
- DSL builders com lambda receivers ou `inline`/`reified` para performance.

## Conteúdo

- `SKILL.md` — modelo mental e padrões de estado e tipos.
- `references/common-utilities.md` — utilitários comuns.
- `references/dsl-builder-examples.md` — exemplos de DSL builders.
- `references/flow-patterns.md` — padrões de Flow/state.
- `references/immutability-patterns.md` — padrões de imutabilidade.
- `references/sealed-class-catalog.md` — catálogo de hierarquias sealed.

## Relação com outras skills

Expert de baixo nível invocado pela `kmp-architect`; complementa `kotlin-coroutines` (async avançado). As convenções de stack do projeto vêm da `kmp-architect`, que documenta o override da stack Amethyst citada aqui — aplique os padrões Kotlin, não as libs específicas do Amethyst.
