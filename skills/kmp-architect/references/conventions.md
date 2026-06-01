# Convenções — Estrutura de Pastas e Nomes

Fonte detalhada da estrutura física e dos nomes. O resumo está no `SKILL.md`; aqui está a árvore completa.

## Visão macro do repositório

```
projeto/
├── shared/                      # módulo KMP único (:shared)
│   ├── build.gradle.kts
│   └── src/
│       ├── commonMain/kotlin/<pkg>/   # TODO o código compartilhado (features + core)
│       ├── commonMain/sqldelight/     # arquivos .sq do SQLDelight
│       ├── androidMain/kotlin/        # actual de expect (ex: DatabaseDriverFactory)
│       ├── iosMain/kotlin/            # actual de expect + export p/ Swift
│       └── commonTest/kotlin/         # testes compartilhados
├── androidApp/                  # app Android (Compose + Navigation Compose)
│   └── src/main/kotlin/...
└── iosApp/                      # app iOS (SwiftUI + NavigationStack)
    └── iosApp/...
```

> `<pkg>` = pacote raiz do app, ex: `com/empresa/app`. Daqui pra frente os caminhos são relativos a
> `shared/src/commonMain/kotlin/<pkg>/`.

## Organização por feature

Cada feature é uma pasta autocontida com as 3 camadas. **Nada de uma feature importa de outra feature** —
o que for comum sobe para `core/`.

```
auth/
├── data/
│   ├── remote/
│   │   ├── AuthApi.kt            # chamadas Ktor da feature
│   │   └── dto/
│   │       ├── LoginRequestDto.kt
│   │       └── UserDto.kt
│   ├── local/
│   │   └── AuthLocalDataSource.kt  # acesso SQLDelight da feature
│   ├── mapper/
│   │   └── UserMapper.kt         # toDomain()/toDto()/toEntity()
│   └── repository/
│       └── AuthRepositoryImpl.kt # implementa domain/repository/AuthRepository
├── domain/
│   ├── model/
│   │   └── User.kt               # model puro, sem anotações de framework
│   ├── repository/
│   │   └── AuthRepository.kt     # interface (contrato)
│   └── usecase/
│       ├── LoginUseCase.kt
│       └── LogoutUseCase.kt
└── presentation/
    └── login/                    # uma sub-pasta por tela quando a feature tem várias
        ├── LoginViewModel.kt
        ├── LoginUiState.kt
        ├── LoginEvent.kt
        └── LoginEffect.kt
```

Para features pequenas (1 tela), o `presentation/` pode conter os arquivos direto, sem a sub-pasta da tela.

## Infra transversal: `core/`

```
core/
├── network/
│   ├── HttpClientFactory.kt     # cria o HttpClient Ktor (engine via expect/actual)
│   ├── ApiConfig.kt             # baseUrl, timeouts, headers padrão
│   ├── AuthInterceptor.kt       # injeta token (Ktor: install + plugin/header)
│   ├── Serialization.kt         # Json { } do kotlinx.serialization
│   └── NetworkResult.kt         # sealed result + safeApiCall()
├── database/
│   ├── DatabaseFactory.kt       # cria SqlDriver (expect/actual)
│   ├── Migrations.kt            # versões/migrações do schema
│   ├── Dao.kt                   # wrappers de query reutilizáveis (opcional)
│   └── Drivers.kt               # DatabaseDriverFactory expect
├── di/
│   ├── NetworkModule.kt         # val networkModule = module { ... }
│   ├── DatabaseModule.kt
│   ├── RepositoryModule.kt
│   ├── ViewModelModule.kt
│   └── AppModules.kt            # lista agregadora p/ startKoin
└── utils/
    ├── DateUtils.kt
    ├── StringUtils.kt
    ├── Validators.kt
    ├── Extensions.kt
    └── Constants.kt
```

> O **driver** do SQLDelight e o **engine** do Ktor variam por plataforma → `expect` em `core/` (commonMain),
> `actual` em `androidMain` (`AndroidSqliteDriver`, engine `OkHttp`/`Android`) e `iosMain`
> (`NativeSqliteDriver`, engine `Darwin`). Decisão de placement → skill **kotlin-multiplatform**.

## Convenção de nomes — completa

### Arquivos e tipos

| Elemento | Convenção | Exemplo |
|----------|-----------|---------|
| Pacote de feature | `lowercase`, singular | `auth`, `note`, `crm` |
| Arquivo | `PascalCase.kt`, 1 tipo público por arquivo | `LoginUseCase.kt` |
| Model de domínio | substantivo, **sem** sufixo, sem anotação | `User`, `Note` |
| Interface repository | `<Feature>Repository` | `AuthRepository` |
| Impl repository | `<Feature>RepositoryImpl` | `AuthRepositoryImpl` |
| Use case | `<Verbo><Substantivo>UseCase` | `LoginUseCase`, `GetNotesUseCase`, `DeleteNoteUseCase` |
| API Ktor (por feature) | `<Feature>Api` | `AuthApi`, `NotesApi` |
| Data source local | `<Feature>LocalDataSource` | `NotesLocalDataSource` |
| DTO de rede | `<Nome><Sufixo>Dto` | `UserDto`, `LoginRequestDto`, `LoginResponseDto` |
| Mapper | `<Nome>Mapper` ou extensões `toDomain()/toDto()/toEntity()` | `UserMapper.kt` |
| ViewModel | `<Tela>ViewModel` | `LoginViewModel` |
| UiState | `<Tela>UiState` — `data class` imutável | `LoginUiState` |
| Event | `<Tela>Event` — `sealed interface` | `LoginEvent` |
| Effect | `<Tela>Effect` — `sealed interface` | `LoginEffect` |
| Módulo Koin | `<area>Module` — `val` | `networkModule`, `repositoryModule` |
| Constantes | `UPPER_SNAKE_CASE` em `object` | `Constants.BASE_URL` |
| Extensão de arquivo | nome pelo tipo estendido | `StringExtensions.kt` |

### SQLDelight (`.sq`)

| Elemento | Convenção | Exemplo |
|----------|-----------|---------|
| Arquivo `.sq` | `PascalCase` do agregado | `Note.sq`, `User.sq` |
| Tabela | `snake_case`, singular | `note`, `user` |
| Query nomeada | `camelCase`, verbo | `selectAll`, `insertNote`, `deleteById` |
| Tipo gerado | `<Tabela>Entity` (configurar) | `NoteEntity` |

### Testes

| Elemento | Convenção | Exemplo |
|----------|-----------|---------|
| Arquivo de teste | `<TipoTestado>Test.kt` | `LoginUseCaseTest.kt`, `LoginViewModelTest.kt` |
| Método de teste | crase, descritivo PT-BR | `` `login com sucesso emite NavigateHome` `` |
| Fake/Stub | `Fake<Interface>` | `FakeAuthRepository` |

## Regras de dependência (verificáveis em review)

1. `domain` **não importa** Ktor, SQLDelight, Koin (a não ser anotações neutras), Android, iOS, kotlinx-coroutines-only-se-necessário.
2. `data` importa `domain` (implementa interfaces); **nunca** importa `presentation`.
3. `presentation` importa `domain` (use cases/models); **nunca** importa `data` diretamente — recebe via DI.
4. Uma feature **não** importa de outra feature. Compartilhamento sobe para `core/`.
5. UI (androidApp/iosApp) importa `presentation` do `:shared`; **nunca** `data` direto.

## Idioma

- **Prosa/comentários/docs**: PT-BR.
- **Identificadores e palavras-chave**: inglês (`LoginUseCase`, `isLoading`, `Submit`).
- **Nomes de teste**: descrição em PT-BR entre crases.
