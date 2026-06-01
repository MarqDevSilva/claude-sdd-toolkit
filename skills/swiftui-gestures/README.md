# swiftui-gestures

> Tratamento de gestos em SwiftUI com composição, estado transiente e resolução de conflitos (iOS 26+).

Cobre gestos de tap, long press, drag, magnify e rotate, composição com `simultaneously`/`sequenced`/`exclusively`, estado transiente com `@GestureState`, resolução de conflitos pai/filho (`highPriorityGesture`, `simultaneousGesture`), conformances customizadas ao protocolo `Gesture` e migração de `MagnificationGesture` para `MagnifyGesture`/`RotateGesture`.

## Quando usar

- Adicionar gestos de tap, long press, drag, magnify ou rotate
- Compor múltiplos gestos (`simultaneously`/`sequenced`/`exclusively`)
- Gerenciar estado transiente de gesto com `@GestureState`
- Resolver conflitos de gesto entre views pai e filho
- Migrar gestos deprecados para as APIs novas (`MagnifyGesture`/`RotateGesture`)

## Conteúdo

- `SKILL.md` — guia principal de gestos SwiftUI
- `references/gesture-patterns.md` — padrões e exemplos de gestos

## Relação com outras skills

Esta skill de UI de plataforma (SwiftUI/iOS) é acionada ATRAVÉS da `kmp-architect`, o hub/roteador do projeto KMP, que decide quando usá-la. Complementa `swiftui-patterns`, `swiftui-layout-components` e `swiftui-animation`.
