# Injeção de Dependência — Koin

DI centralizado em `core/di/`. Um módulo Koin por responsabilidade. A regra: **registre interfaces, injete
abstrações**. ViewModel recebe use cases; use case recebe repository (interface); repository recebe API + data source.

## Um módulo por responsabilidade

```kotlin
// core/di/NetworkModule.kt
import org.koin.dsl.module

val networkModule = module {
    single { ApiConfig(baseUrl = "https://api.empresa.com") }
    single { provideJson() }                    // kotlinx.serialization Json
    single { HttpClientFactory(get()).create() } // get() = engine via expect/actual
}
```

```kotlin
// core/di/DatabaseModule.kt
val databaseModule = module {
    single { DatabaseDriverFactory().create() }  // SqlDriver (expect/actual)
    single { AppDatabase(get()) }
    single { Dispatchers.IO } // ou um provider de dispatcher; ver kotlin-coroutines
}
```

```kotlin
// core/di/RepositoryModule.kt
val repositoryModule = module {
    // data sources
    factory { AuthApi(get(), get()) }
    factory { AuthLocalDataSource(get(), get()) }
    // repository: bind da interface para a impl
    single<AuthRepository> { AuthRepositoryImpl(get(), get()) }

    // use cases
    factory { LoginUseCase(get()) }
    factory { LogoutUseCase(get()) }
}
```

```kotlin
// core/di/ViewModelModule.kt — usa koin-core (multiplataforma)
import org.koin.core.module.dsl.factoryOf
import org.koin.dsl.module

val viewModelModule = module {
    factory { LoginViewModel(get()) }
    // Em Android, prefira viewModelOf { } do koin-androidx-compose quando o ViewModel
    // for resolvido pelo ciclo de vida da tela. Ver skill android-expert.
}
```

```kotlin
// core/di/AppModules.kt — agregador para startKoin
val appModules = listOf(
    networkModule,
    databaseModule,
    repositoryModule,
    viewModelModule,
)
```

## Inicialização por plataforma

### Função comum (commonMain)

```kotlin
// core/di/KoinInit.kt
import org.koin.core.context.startKoin
import org.koin.core.KoinApplication

fun initKoin(appDeclaration: KoinApplication.() -> Unit = {}) =
    startKoin {
        appDeclaration()
        modules(appModules)
    }
```

### Android

```kotlin
// androidApp Application
class App : Application() {
    override fun onCreate() {
        super.onCreate()
        initKoin {
            androidContext(this@App)   // koin-android: provê Context p/ driver SQLDelight
        }
    }
}
```

### iOS

```kotlin
// iosMain — exposto para Swift
fun initKoinIos() = initKoin()
```

```swift
// iosApp — em @main App ou AppDelegate
KoinInitKt.doInitKoinIos()
```

> O **engine do Ktor** e o **driver do SQLDelight** são `expect/actual` (Android: `OkHttp`/`AndroidSqliteDriver`;
> iOS: `Darwin`/`NativeSqliteDriver`). Decisão de placement e assinatura → skill **kotlin-multiplatform**.
> Conflitos de versão/build do Koin → skill **gradle-expert** (lembre o override da Stack Canônica).

## Convenções

| Item | Regra |
|------|-------|
| Nome do módulo | `<area>Module` (`val`), em `core/di/` |
| `single` vs `factory` | `single` para infra/repos com estado de conexão; `factory` para use cases e ViewModels |
| Bind de interface | `single<AuthRepository> { AuthRepositoryImpl(...) }` — sempre exponha a interface |
| Onde registrar | use case e repository de uma feature ficam em `repositoryModule` (ou um módulo por feature se crescer) |
| Acesso a dependência | por construtor; evite `KoinComponent`/`get()` espalhado pelo código |

## Quando uma feature cresce

Se `repositoryModule` ficar grande, quebre por feature mantendo o agregador:

```kotlin
// auth/di/AuthModule.kt
val authModule = module { /* AuthApi, AuthRepositoryImpl, LoginUseCase, LoginViewModel */ }

// core/di/AppModules.kt
val appModules = listOf(networkModule, databaseModule, authModule, notesModule, /* ... */)
```
