# swiftui-patterns

> Padrões modernos de SwiftUI para estruturar views, estado e composição (iOS 26+, Swift 6.3).

Cobre a arquitetura Model-View (MV), regras de ownership de `@Observable`, wiring de `@State`/`@Bindable`/`@Environment`, decomposição de views, `ViewModifier` customizados, environment values, carregamento assíncrono com `.task`, APIs novas do iOS 26+, Writing Tools e guidelines de performance. Navegação e layout ficam em skills irmãs dedicadas.

## Quando usar

- Estruturar um app SwiftUI e definir ownership de estado com `@Observable`
- Decidir entre `@State`, `let`, `@Bindable` e `@Environment`
- Compor hierarquias de view e extrair subviews / `ViewModifier`
- Carregar dados async com `.task` / `.task(id:)`
- Aplicar boas práticas e checklist de revisão SwiftUI

## Conteúdo

- `SKILL.md` — guia principal de padrões e estado em SwiftUI
- `references/architecture-patterns.md` — racional do MV, app wiring e clients
- `references/deprecated-migration.md` — migração de APIs deprecadas
- `references/design-polish.md` — HIG, theming, haptics, focus, transitions
- `references/platform-and-sharing.md` — Transferable, mídia, menus, settings macOS

## Relação com outras skills

Esta skill de UI de plataforma (SwiftUI/iOS) é acionada ATRAVÉS da `kmp-architect`, o hub/roteador do projeto KMP, que decide quando usá-la. Navegação fica na `swiftui-navigation` e layout/componentes na `swiftui-layout-components`.
