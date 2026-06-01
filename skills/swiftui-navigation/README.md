# swiftui-navigation

> Padrões de navegação em SwiftUI: `NavigationStack`, `NavigationSplitView`, sheets, tabs e deep linking (iOS 26+).

Cobre push navigation type-safe com `NavigationStack` e `NavigationPath`, layouts multi-coluna com `NavigationSplitView`, apresentação de sheets (`.sheet(item:)`, `presentationSizing`), arquitetura de tabs com o API `Tab` e roteamento programático. Inclui deep links via universal links, custom URL schemes e Handoff (`NSUserActivity`).

## Quando usar

- Push navigation e roteamento programático com `NavigationStack`
- Layouts sidebar-detalhe (iPad/Mac) com `NavigationSplitView`
- Apresentação de sheets modais e roteamento por enum
- Arquitetura de tabs com `TabView`/`Tab` e router por tab
- Deep linking: universal links, custom URL schemes, Handoff

## Conteúdo

- `SKILL.md` — guia principal de navegação SwiftUI
- `references/navigationstack.md` — `NavigationStack` e padrões de router
- `references/sheets.md` — apresentação e roteamento de sheets
- `references/tabview.md` — padrões de `TabView` e APIs do iOS 26
- `references/deeplinks.md` — universal links, URL schemes e Handoff

## Relação com outras skills

Esta skill de UI de plataforma (SwiftUI/iOS) é acionada ATRAVÉS da `kmp-architect`, o hub/roteador do projeto KMP, que decide quando usá-la. Arquitetura/estado ficam na `swiftui-patterns` e layout na `swiftui-layout-components`.
