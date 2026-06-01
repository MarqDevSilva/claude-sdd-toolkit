# kmp-architect

> Hub de convenções e roteador de skills do projeto Kotlin Multiplatform.

Fonte única de verdade da arquitetura do projeto KMP (MVVM + Clean num módulo `:shared` único, com `domain/data/presentation` por feature) e ponto de entrada que decide qual expert acionar. Define a stack canônica (Ktor + kotlinx.serialization + SQLDelight + Koin + StateFlow; Android com Jetpack Compose + Navigation Compose; iOS com SwiftUI + NavigationStack), nomes, estrutura de pastas, tratamento de erros, DI e o que compartilhar vs manter platform-specific.

## Quando usar

- Antes de escrever qualquer código KMP/Compose/SwiftUI no projeto.
- Ao criar ViewModel, Repository ou UseCase e decidir onde colocá-los.
- Para checar convenção de nomes, estrutura de pastas, tratamento de erro ou módulo Koin.
- Para descobrir qual expert invocar via a Tabela de Roteamento.

## Conteúdo

- `SKILL.md` — convenções canônicas, stack, roteamento e override da stack Amethyst.
- `references/architecture-layers.md` — camadas e fluxo domain/data/presentation.
- `references/conventions.md` — nomes, pastas e padrões de código.
- `references/error-handling.md` — padrão de tratamento de erros.
- `references/koin-di.md` — organização dos módulos Koin.
- `references/testing.md` — convenções de teste.
- `scripts/scaffold-feature.sh` — gera o esqueleto de uma feature.

## Relação com outras skills

É o ponto de entrada e roteador do projeto: aplica as convenções deste hub (que têm prioridade) e delega detalhes idiomáticos para os experts `kotlin-multiplatform`, `kotlin-expert`, `kotlin-coroutines`, `gradle-expert`, `compose-expert` e os experts SwiftUI/Android.
