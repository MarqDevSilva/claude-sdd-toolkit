# swiftui-liquid-glass

> Efeitos Liquid Glass em SwiftUI — o material translúcido dinâmico do iOS 26+.

Cobre o modifier `glassEffect`, `GlassEffectContainer`, glass button styles, glass toolbar e tab bar, transições de morphing (`glassEffectID`, `GlassEffectTransition`, `glassEffectUnion`), material translúcido, vibrancy, tinting, glass interativo, `ToolbarSpacer`, `scrollEdgeEffectStyle`, `backgroundExtensionEffect` e gating de disponibilidade (`if #available(iOS 26, *)`).

## Quando usar

- Aplicar Liquid Glass a cards, chips, controles flutuantes e bars customizadas
- Usar `.glassEffect()` e agrupar elementos em `GlassEffectContainer`
- Trocar botões custom por `.buttonStyle(.glass)` / `.glassProminent`
- Adicionar transições de morphing com `glassEffectID`
- Adotar o design iOS 26 com gating de disponibilidade e fallback

## Conteúdo

- `SKILL.md` — guia principal com workflow e core API summary
- `references/liquid-glass.md` — referência completa da API com exemplos

## Relação com outras skills

Esta skill de UI de plataforma (SwiftUI/iOS) é acionada ATRAVÉS da `kmp-architect`, o hub/roteador do projeto KMP, que decide quando usá-la. Complementa `swiftui-patterns`, `swiftui-navigation` e `swiftui-layout-components`.
