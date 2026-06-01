---
name: kmp-architect
description: |
  Hub de convenções e roteador de skills para um projeto Kotlin Multiplatform moderno
  (shared = KMP + Koin + Ktor + SQLDelight + StateFlow; Android = Jetpack Compose + Navigation Compose;
  iOS = SwiftUI + NavigationStack). Define a fonte única de verdade de arquitetura (MVVM + Clean compartilhado
  com domain/data/presentation por feature em um módulo :shared único), nomes, estrutura de pastas, padrões de
  código, tratamento de erros, DI com Koin, testes e o que compartilhar vs manter platform-specific. SEMPRE
  consulte esta skill ANTES de escrever código KMP/Compose/SwiftUI no projeto, e use a Tabela de Roteamento para
  decidir qual skill de expert invocar (android-expert, compose-expert, kotlin-expert, kotlin-coroutines,
  kotlin-multiplatform, gradle-expert, swiftui-patterns, swiftui-navigation, swiftui-layout-components,
  swiftui-animation, swiftui-gestures, swiftui-liquid-glass).
  Triggers: "novo feature KMP", "onde coloco esse código", "como o projeto organiza X", "criar ViewModel/Repository/UseCase",
  "estrutura de pastas", "convenção de nomes", "tratamento de erro", "módulo Koin", "tela Android/iOS".
---

# KMP Architect — Hub de Convenções do Projeto

Fonte única de verdade da arquitetura deste projeto **Kotlin Multiplatform** e roteador para as skills de expert.
Quem gera código (ViewModel, Repository, UseCase, tela Compose/SwiftUI) **lê esta skill primeiro** para seguir o
mesmo padrão, e depois delega detalhes idiomáticos para a skill de expert certa via a [Tabela de Roteamento](#tabela-de-roteamento).

## Como usar esta skill

1. **Antes de qualquer tarefa de código**, identifique a camada/plataforma envolvida.
2. Aplique as **convenções deste hub** (nomes, pastas, padrões, erros, testes) — elas têm prioridade.
3. Use a **Tabela de Roteamento** para invocar a skill de expert que cobre os detalhes idiomáticos.
4. **Override Amethyst:** as skills de expert (android-expert, kotlin-*, compose-expert, gradle-expert) foram
   escritas para o projeto *Amethyst* e citam libs dele (Jackson, OkHttp, jvmAndroid, secp256k1, Desktop/JVM target).
   Este projeto **não usa** essas escolhas. Quando houver conflito, vale a [Stack Canônica](#stack-canônica) deste hub:
   **Ktor + kotlinx.serialization + SQLDelight + Koin**, alvos **Android + iOS** (sem Desktop). Use os experts pelos
   *padrões* (StateFlow, sealed classes, Navigation Compose, NavigationStack), não pelas libs específicas do Amethyst.

## Stack Canônica

| Camada | Tecnologia | Observação |
|--------|-----------|------------|
| **Shared** | Kotlin Multiplatform | Alvos: `androidTarget`, `iosArm64`, `iosSimulatorArm64`, `iosX64` |
| Shared · DI | **Koin** | Módulos por responsabilidade (`networkModule`, `databaseModule`, `repositoryModule`, `viewModelModule`) |
| Shared · Rede | **Ktor Client** | `HttpClient` + `ContentNegotiation` com **kotlinx.serialization** |
| Shared · Persistência | **SQLDelight** | `.sq` files, driver via `expect/actual` por plataforma |
| Shared · Estado | **StateFlow** | `StateFlow<UiState>` exposto pelos ViewModels compartilhados |
| **Android** | **Jetpack Compose** + **Navigation Compose** | UI e navegação **platform-specific** (não compartilhadas) |
| **iOS** | **SwiftUI** + **NavigationStack** | UI e navegação **platform-specific** (não compartilhadas) |

> Detalhes de versões e `libs.versions.toml` → invoque **gradle-expert** (lendo a ressalva de override acima).

## O que compartilhar vs manter platform-specific

**Compartilhado em `commonMain` (`:shared`):**
- ✅ **Domain** — models, contratos de repository, use cases (Kotlin puro, sem API/DB/UI)
- ✅ **Data** — implementações de repository, Ktor (remote), SQLDelight (local), mappers
- ✅ **ViewModels** + `UiState`/`Event`/`Effect` (StateFlow)

**Platform-specific (nunca compartilhar):**
- ❌ **Navegação** — Navigation Compose (Android) vs NavigationStack (iOS)
- ❌ **Componentes visuais** — Composables vs SwiftUI Views
- ❌ **Permissões** — APIs Android vs iOS incompatíveis
- ❌ **Recursos específicos da plataforma** — Context/Intent, UIKit, notificações, etc.

> Em dúvida sobre onde um código mora ou se deve virar `expect/actual` → invoque **kotlin-multiplatform**.

## Tabela de Roteamento

Mapeia o tipo de tarefa → skill de expert a invocar. As **convenções deste hub continuam valendo** por cima.

### Shared (Kotlin / KMP)

| Tarefa | Skill | Convenção deste hub a aplicar |
|--------|-------|-------------------------------|
| Onde colocar código? Compartilhar ou não? `expect/actual`, source sets | **kotlin-multiplatform** | Regras de "compartilhar vs platform-specific" acima |
| StateFlow/SharedFlow, sealed classes, `@Immutable`, data classes, DSL | **kotlin-expert** | `UiState` é `data class` imutável; eventos/effects são `sealed interface` |
| Corrotinas: `Flow` operators, `combine`, structured concurrency, testar async (`runTest`/Turbine) | **kotlin-coroutines** | Repos retornam `Flow`; ViewModel coleta em `viewModelScope` |
| `build.gradle.kts`, `libs.versions.toml`, source sets, erros de build, deps | **gradle-expert** | Override Amethyst → Stack Canônica deste hub |
| Lógica de UI compartilhável em Compose Multiplatform (raro aqui) | **compose-expert** | Por padrão UI é platform-specific; só compartilhe se intencional |

### Android (Jetpack Compose)

| Tarefa | Skill | Convenção deste hub a aplicar |
|--------|-------|-------------------------------|
| Navigation Compose, rotas `@Serializable`, bottom bar, deep links | **android-expert** | Rotas type-safe; `collectAsStateWithLifecycle` no `UiState` do ViewModel shared |
| Material3, edge-to-edge, theming, permissões, lifecycle, Intent/Context | **android-expert** | Permissões e Context ficam só no módulo Android |
| Padrões de Composable, `remember`, recomposição, estado visual | **compose-expert** | ViewModel vem do `:shared`; a tela só renderiza `UiState` e emite `Event` |

### iOS (SwiftUI)

| Tarefa | Skill | Convenção deste hub a aplicar |
|--------|-------|-------------------------------|
| Estrutura de View, `@Observable`, `@State`/`@Bindable`, composição, `.task` | **swiftui-patterns** | Wrapper `@Observable` observa o `StateFlow` do ViewModel shared (via Flow→async) |
| NavigationStack, sheets, tabs, deep linking, rotas programáticas | **swiftui-navigation** | Navegação mora no iOS; nunca no `:shared` |
| Stacks, grids, List, Form, controles, `.searchable`, overlays | **swiftui-layout-components** | Telas renderizam o `UiState` exposto pelo ViewModel shared |
| Animações, transitions, SF Symbols, matchedGeometryEffect | **swiftui-animation** | — |
| Gestos (tap, drag, magnify, rotate, composição) | **swiftui-gestures** | — |
| Liquid Glass / efeitos iOS 26+ (`glassEffect`, glass toolbar/tab bar) | **swiftui-liquid-glass** | Gate por disponibilidade (`if #available`) |

### Quando NÃO rotear (resolver aqui)

- Estrutura de pastas / nome de arquivo → [references/conventions.md](references/conventions.md)
- Padrão de Repository/UseCase/ViewModel → [references/architecture-layers.md](references/architecture-layers.md)
- Tratamento de erro / `NetworkResult` → [references/error-handling.md](references/error-handling.md)
- Módulo Koin / DI → [references/koin-di.md](references/koin-di.md)
- Convenção de testes → [references/testing.md](references/testing.md)
- Scaffolding de uma feature nova → [scripts/scaffold-feature.sh](scripts/scaffold-feature.sh)

## Arquitetura em uma tela

**MVVM + Clean compartilhado**, organizado por **feature** dentro de um único módulo `:shared`.

```
UI (Android Compose / iOS SwiftUI)   ← platform-specific
        │ observa StateFlow<UiState> / emite Event
        ▼
presentation/  ViewModel + UiState + Event + Effect   ← commonMain (shared)
        │ chama
        ▼
domain/  UseCase → Repository (interface) + Model      ← commonMain (Kotlin puro)
        ▲ implementado por
        │
data/    RepositoryImpl + remote(Ktor) + local(SQLDelight) + mapper  ← commonMain
```

**Regra de dependência (Clean):** `presentation → domain ← data`. O `domain` não conhece Ktor, SQLDelight,
Android nem iOS. O `data` implementa as interfaces do `domain`. A UI só fala com `presentation`.

## Estrutura de Pastas (resumo)

```
shared/src/commonMain/kotlin/<pkg>/
├── auth/                      # uma pasta por feature
│   ├── data/        ( remote/ local/ mapper/ repository/ )
│   ├── domain/      ( model/ repository/ usecase/ )
│   └── presentation/( AuthViewModel, AuthUiState, AuthEvent, AuthEffect )
├── notes/  ...
├── crm/    ...
└── core/                      # infra transversal
    ├── network/   ( HttpClientFactory, ApiConfig, AuthInterceptor, Serialization, NetworkResult )
    ├── database/  ( DatabaseFactory, Migrations, Dao, Drivers )
    ├── di/        ( NetworkModule, DatabaseModule, RepositoryModule, ViewModelModule )
    └── utils/     ( DateUtils, StringUtils, Validators, Extensions, Constants )
```

Árvore completa + sub-pastas de cada camada → [references/conventions.md](references/conventions.md).

## Convenções de Nomes (essencial)

| Elemento | Convenção | Exemplo |
|----------|-----------|---------|
| Pacote de feature | minúsculo, singular | `auth`, `notes`, `crm` |
| Model de domínio | substantivo, sem sufixo | `User`, `Note` |
| Interface de repository | `<Feature>Repository` | `AuthRepository` |
| Implementação | `<Feature>RepositoryImpl` | `AuthRepositoryImpl` |
| Use case | verbo + substantivo + `UseCase` | `LoginUseCase`, `GetNotesUseCase` |
| ViewModel | `<Tela>ViewModel` | `LoginViewModel` |
| Estado de UI | `<Tela>UiState` (data class) | `LoginUiState` |
| Evento (input do user) | `<Tela>Event` (sealed interface) | `LoginEvent` |
| Efeito one-shot (nav/toast) | `<Tela>Effect` (sealed interface) | `LoginEffect` |
| DTO de rede | `<Nome>Dto` | `UserDto` |
| Entidade SQLDelight | tabela no `.sq`; gerado `<Nome>Entity` | `NoteEntity` |
| Mapper | `<Nome>Mapper` ou extensão `toDomain()/toDto()/toEntity()` | `UserMapper` |
| Módulo Koin | `<area>Module` (val) | `networkModule` |

Detalhe completo (nomes de arquivos, testes, `.sq`) → [references/conventions.md](references/conventions.md).

## Padrão de presentation (UDF)

Cada tela expõe **um** `StateFlow<UiState>`, recebe **`Event`** do usuário e emite **`Effect`** one-shot:

```kotlin
data class LoginUiState(
    val email: String = "",
    val password: String = "",
    val isLoading: Boolean = false,
    val error: String? = null,
)

sealed interface LoginEvent {
    data class EmailChanged(val value: String) : LoginEvent
    data class PasswordChanged(val value: String) : LoginEvent
    data object Submit : LoginEvent
}

sealed interface LoginEffect {
    data object NavigateHome : LoginEffect
    data class ShowError(val message: String) : LoginEffect
}

class LoginViewModel(
    private val login: LoginUseCase,
) : ViewModel() {                                  // androidx.lifecycle (KMP) ViewModel
    private val _state = MutableStateFlow(LoginUiState())
    val state: StateFlow<LoginUiState> = _state.asStateFlow()

    private val _effect = Channel<LoginEffect>(Channel.BUFFERED)
    val effect = _effect.receiveAsFlow()

    fun onEvent(event: LoginEvent) {
        when (event) {
            is LoginEvent.EmailChanged -> _state.update { it.copy(email = event.value) }
            is LoginEvent.PasswordChanged -> _state.update { it.copy(password = event.value) }
            LoginEvent.Submit -> submit()
        }
    }

    private fun submit() = viewModelScope.launch {
        _state.update { it.copy(isLoading = true, error = null) }
        when (val result = login(_state.value.email, _state.value.password)) {
            is NetworkResult.Success -> _effect.send(LoginEffect.NavigateHome)
            is NetworkResult.Error -> _state.update { it.copy(error = result.message) }
        }
        _state.update { it.copy(isLoading = false) }
    }
}
```

Exemplos completos das 3 camadas (UseCase, RepositoryImpl, remote/local, mapper) →
[references/architecture-layers.md](references/architecture-layers.md).

## Tratamento de Erros (resumo)

Camada de rede/repository devolve `NetworkResult<T>` (sealed). O `domain`/`presentation` decide a mensagem.
Nunca vaze exceção crua para a UI.

```kotlin
sealed interface NetworkResult<out T> {
    data class Success<T>(val data: T) : NetworkResult<T>
    data class Error(val type: ErrorType, val message: String) : NetworkResult<Nothing>
}

enum class ErrorType { NETWORK, UNAUTHORIZED, NOT_FOUND, SERVER, SERIALIZATION, UNKNOWN }
```

Mapeamento de exceções Ktor/SQLDelight → `ErrorType` em [references/error-handling.md](references/error-handling.md).

## Checklist antes de entregar uma feature

- [ ] Código na camada certa (`domain` sem deps de framework; `data` implementa interfaces do `domain`)
- [ ] Feature isolada na própria pasta; infra transversal em `core/`
- [ ] Nomes seguindo a tabela de convenções
- [ ] ViewModel expõe `StateFlow<UiState>`; eventos via `onEvent(Event)`; one-shot via `Effect`
- [ ] Erros tratados com `NetworkResult` — nada de exceção crua na UI
- [ ] DI registrado no módulo Koin correto
- [ ] Navegação e UI **não** entraram no `:shared`
- [ ] Testes: UseCase e ViewModel com `runTest` (ver [references/testing.md](references/testing.md))

## Referências

- [references/conventions.md](references/conventions.md) — estrutura de pastas completa + nomes de arquivos
- [references/architecture-layers.md](references/architecture-layers.md) — padrões de código por camada (domain/data/presentation) com exemplos
- [references/error-handling.md](references/error-handling.md) — `NetworkResult`, mapeamento de erros Ktor/SQLDelight
- [references/koin-di.md](references/koin-di.md) — módulos Koin e wiring Android/iOS
- [references/testing.md](references/testing.md) — convenções de teste (commonTest, runTest, Turbine, fakes)
- [scripts/scaffold-feature.sh](scripts/scaffold-feature.sh) — gera o esqueleto data/domain/presentation de uma feature
