# swiftui-animation

> Animações e transições em SwiftUI com timing, springs e acessibilidade corretos (iOS 26+).

Cobre animações explícitas (`withAnimation`) e implícitas (`.animation(_:value:)`), springs (`.smooth`/`.snappy`/`.bouncy`), animações multi-fase com `PhaseAnimator` e `KeyframeAnimator`, hero transitions (`matchedGeometryEffect`, `matchedTransitionSource`), `Transition`/`CustomAnimation` customizados, efeitos de SF Symbols e respeito a `accessibilityReduceMotion`.

## Quando usar

- Adicionar animações explícitas ou implícitas a mudanças de estado
- Configurar springs (`.smooth`, `.snappy`, `.bouncy`)
- Construir animações com `PhaseAnimator` / `KeyframeAnimator`
- Criar hero transitions e zoom transitions de navegação
- Adicionar `symbolEffect` e garantir acessibilidade (reduce motion)

## Conteúdo

- `SKILL.md` — guia principal de animações SwiftUI com triage workflow
- `references/animation-advanced.md` — padrões avançados de animação
- `references/core-animation-bridge.md` — ponte com Core Animation

## Relação com outras skills

Esta skill de UI de plataforma (SwiftUI/iOS) é acionada ATRAVÉS da `kmp-architect`, o hub/roteador do projeto KMP, que decide quando usá-la. Complementa `swiftui-patterns`, `swiftui-navigation` e `swiftui-layout-components`.
