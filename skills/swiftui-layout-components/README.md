# swiftui-layout-components

> Layouts e componentes SwiftUI: stacks, grids, lists, scroll views, forms e controls (iOS 26+).

Cobre fundamentos de layout (`VStack`/`HStack`/`ZStack` e versões lazy), grids (`LazyVGrid`/`LazyHGrid`), `List` com sections e swipe actions, `ScrollView` com `ScrollPosition`, `Form` com validação, controls (`Toggle`/`Picker`/`Slider`), busca com `.searchable` e padrões de overlay/apresentação transiente.

## Quando usar

- Montar layouts data-driven com stacks e grids
- Construir collection views e galerias com `LazyVGrid`/`LazyHGrid`
- Telas de lista com sections, swipe actions e scroll posicionado
- Telas de settings com `Form` e controls validados
- Interfaces de busca com `.searchable` e overlays transientes

## Conteúdo

- `SKILL.md` — guia principal de layout e componentes SwiftUI
- `references/form.md` — `Form`, controls e validação
- `references/grids.md` — `LazyVGrid`/`LazyHGrid` e colunas adaptativas
- `references/list.md` — `List`, sections e swipe actions
- `references/scrollview.md` — `ScrollView` e `ScrollPosition`

## Relação com outras skills

Esta skill de UI de plataforma (SwiftUI/iOS) é acionada ATRAVÉS da `kmp-architect`, o hub/roteador do projeto KMP, que decide quando usá-la. Arquitetura/estado ficam na `swiftui-patterns` e navegação na `swiftui-navigation`.
