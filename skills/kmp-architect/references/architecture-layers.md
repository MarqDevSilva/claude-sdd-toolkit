# Padrões de Código por Camada

Exemplos canônicos de cada camada para a feature `auth`. Copie a forma, adapte o conteúdo.
A regra de dependência é `presentation → domain ← data` (ver `conventions.md`).

---

## domain/ — coração do negócio

Kotlin puro. **Nada** de Ktor, SQLDelight, Koin (exceto se usar `@Factory` etc., evite), Android ou iOS.

### model/

```kotlin
// auth/domain/model/User.kt
data class User(
    val id: String,
    val name: String,
    val email: String,
)
```

### repository/ (contrato)

```kotlin
// auth/domain/repository/AuthRepository.kt
import com.empresa.app.core.network.NetworkResult
import kotlinx.coroutines.flow.Flow

interface AuthRepository {
    suspend fun login(email: String, password: String): NetworkResult<User>
    suspend fun logout()
    fun observeCurrentUser(): Flow<User?>   // leitura reativa via SQLDelight
}
```

### usecase/

Um use case = uma intenção de negócio. `operator fun invoke` para chamar como função.
Validações de regra de negócio moram aqui (não no ViewModel, não no repository).

```kotlin
// auth/domain/usecase/LoginUseCase.kt
import com.empresa.app.core.network.NetworkResult
import com.empresa.app.core.network.ErrorType

class LoginUseCase(
    private val repository: AuthRepository,
) {
    suspend operator fun invoke(email: String, password: String): NetworkResult<User> {
        if (!email.contains("@")) {
            return NetworkResult.Error(ErrorType.UNKNOWN, "E-mail inválido")
        }
        if (password.length < 6) {
            return NetworkResult.Error(ErrorType.UNKNOWN, "Senha muito curta")
        }
        return repository.login(email.trim(), password)
    }
}
```

> Regra de ouro: se a tela A e a tela B precisam da mesma lógica, ela é um **use case**, não código duplicado
> no ViewModel.

---

## data/ — implementa os contratos do domain

### remote/ (Ktor)

DTOs são `@Serializable` e ficam **só** na camada data. Nunca exponha DTO para `domain`/`presentation`.

```kotlin
// auth/data/remote/dto/UserDto.kt
import kotlinx.serialization.Serializable

@Serializable
data class UserDto(
    val id: String,
    val name: String,
    val email: String,
)

// auth/data/remote/dto/LoginRequestDto.kt
@Serializable
data class LoginRequestDto(val email: String, val password: String)
```

```kotlin
// auth/data/remote/AuthApi.kt
import io.ktor.client.HttpClient
import io.ktor.client.request.post
import io.ktor.client.request.setBody
import io.ktor.http.ContentType
import io.ktor.http.contentType

class AuthApi(
    private val client: HttpClient,
    private val config: ApiConfig,
) {
    suspend fun login(body: LoginRequestDto) =
        client.post("${config.baseUrl}/auth/login") {
            contentType(ContentType.Application.Json)
            setBody(body)
        }
}
```

### local/ (SQLDelight)

```kotlin
// auth/data/local/AuthLocalDataSource.kt
import com.empresa.app.db.AppDatabase
import kotlinx.coroutines.flow.Flow
import app.cash.sqldelight.coroutines.asFlow
import app.cash.sqldelight.coroutines.mapToOneOrNull

class AuthLocalDataSource(
    private val db: AppDatabase,
    private val dispatcher: CoroutineDispatcher,   // injete; ver kotlin-coroutines
) {
    fun observeUser(): Flow<UserEntity?> =
        db.userQueries.selectCurrent().asFlow().mapToOneOrNull(dispatcher)

    fun upsert(entity: UserEntity) =
        db.userQueries.upsert(entity.id, entity.name, entity.email)

    fun clear() = db.userQueries.deleteAll()
}
```

### mapper/

Conversões `DTO ↔ domain ↔ entity` como funções de extensão. Mantém `domain` limpo de tipos de framework.

```kotlin
// auth/data/mapper/UserMapper.kt
fun UserDto.toDomain() = User(id = id, name = name, email = email)
fun User.toEntity() = UserEntity(id = id, name = name, email = email)
fun UserEntity.toDomain() = User(id = id, name = name, email = email)
```

### repository/ (implementação)

Orquestra remote + local, mapeia, devolve `NetworkResult`/`Flow` de **tipos do domain**.

```kotlin
// auth/data/repository/AuthRepositoryImpl.kt
import com.empresa.app.core.network.NetworkResult
import com.empresa.app.core.network.safeApiCall
import io.ktor.client.call.body
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

class AuthRepositoryImpl(
    private val api: AuthApi,
    private val local: AuthLocalDataSource,
) : AuthRepository {

    override suspend fun login(email: String, password: String): NetworkResult<User> =
        safeApiCall {
            val dto: UserDto = api.login(LoginRequestDto(email, password)).body()
            local.upsert(dto.toDomain().toEntity())
            dto.toDomain()
        }

    override suspend fun logout() = local.clear()

    override fun observeCurrentUser(): Flow<User?> =
        local.observeUser().map { it?.toDomain() }
}
```

> `safeApiCall { }` encapsula o try/catch e o mapeamento de exceções → `NetworkResult.Error`.
> Definição em [error-handling.md](error-handling.md).

---

## presentation/ — prepara dados para a UI (UDF)

Contrato por tela: `UiState` (estado) + `Event` (input do usuário) + `Effect` (one-shot).
O exemplo completo do `LoginViewModel` está no `SKILL.md`. Pontos de convenção:

- **`UiState`** é `data class` imutável; atualize com `_state.update { it.copy(...) }`.
- **`Event`** é `sealed interface`; o único ponto de entrada da UI é `onEvent(event: Event)`.
- **`Effect`** é `sealed interface` entregue por `Channel` → `receiveAsFlow()` (one-shot, não re-emite em recomposição/rotação).
- ViewModel recebe **use cases** por construtor (DI Koin), nunca repositories diretamente quando há regra.
- Nada de tipo de UI (Composable, SwiftUI) aqui — só estado/dados.

```kotlin
// auth/presentation/login/LoginUiState.kt
data class LoginUiState(
    val email: String = "",
    val password: String = "",
    val isLoading: Boolean = false,
    val error: String? = null,
) {
    val canSubmit: Boolean get() = email.isNotBlank() && password.isNotBlank() && !isLoading
}
```

> `ViewModel` e `viewModelScope` vêm de `androidx.lifecycle:lifecycle-viewmodel` (suporta KMP).
> No iOS, o ViewModel é consumido via wrapper `@Observable` que observa o `StateFlow` — ver skill **swiftui-patterns**.

---

## Conectando na UI (resumo — detalhe nas skills de plataforma)

### Android (Compose) → skill **android-expert** / **compose-expert**

```kotlin
@Composable
fun LoginScreen(viewModel: LoginViewModel, onNavigateHome: () -> Unit) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    LaunchedEffect(Unit) {
        viewModel.effect.collect { effect ->
            when (effect) {
                LoginEffect.NavigateHome -> onNavigateHome()
                is LoginEffect.ShowError -> { /* snackbar */ }
            }
        }
    }
    // render state, chamar viewModel.onEvent(...)
}
```

### iOS (SwiftUI) → skill **swiftui-patterns** / **swiftui-navigation**

Crie um `@Observable` que assina o `StateFlow` (via `collect` em `Task`) e repassa `onEvent`.
A navegação reage ao `Effect` dentro do `NavigationStack` (ver **swiftui-navigation**).
