# android-expert

> Expertise da plataforma Android (Jetpack Compose) para a camada de UI de um app KMP.

Cobre os padrões específicos de Android: Navigation Compose com rotas `@Serializable` type-safe, permissões em runtime (Accompanist), Material3 e edge-to-edge, lifecycle (`ViewModel`, `collectAsStateWithLifecycle`), APIs de plataforma (`Intent`, `Context`, `Activity`, deep links), além de build (`Proguard`, otimização de APK). A skill foi escrita originalmente para o app Amethyst e ainda cita detalhes dele como exemplo.

## Quando usar

- Navegação Android (Navigation Compose, rotas, bottom nav, deep links)
- Permissões em runtime (camera, notifications, biometric)
- Material3, theming e edge-to-edge com `Scaffold`/insets
- Lifecycle Android (`ViewModel`, `LifecycleResumeEffect`, `collectAsStateWithLifecycle`)
- APIs de plataforma (`Intent`, `Context`, `FileProvider`, Activity results)
- Build Android (Proguard, análise de tamanho de APK)

## Conteúdo

- `SKILL.md` — guia principal com padrões de Android no projeto KMP
- `references/android-navigation.md` — padrões completos de Navigation Compose
- `references/android-permissions.md` — padrões de permissões em runtime
- `references/image-loading.md` — Coil 3.x, fetchers customizados e helpers de imagem
- `references/proguard-rules.md` — configuração de Proguard/R8
- `scripts/analyze-apk-size.sh` — script de análise de tamanho de APK

## Relação com outras skills

Esta é uma skill de UI de plataforma e é acionada ATRAVÉS da `kmp-architect`, o hub/roteador do projeto KMP, que decide quando usá-la. As convenções de arquitetura do projeto (MVVM + Clean compartilhado, `StateFlow` vindo do módulo `:shared`) são definidas pela `kmp-architect` — use os exemplos do Amethyst aqui apenas como referência de padrão, não como convenção do projeto.
