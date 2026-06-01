# Tratamento de Erros

Regra central: **a UI nunca vê uma exceção crua**. A borda de I/O (Ktor/SQLDelight) converte falhas em um tipo
de resultado tipado (`NetworkResult`), e a camada de apresentação decide a mensagem.

## NetworkResult — o tipo de resultado

Mora em `core/network/NetworkResult.kt`.

```kotlin
sealed interface NetworkResult<out T> {
    data class Success<T>(val data: T) : NetworkResult<T>
    data class Error(val type: ErrorType, val message: String) : NetworkResult<Nothing>
}

enum class ErrorType {
    NETWORK,        // sem conexão, timeout
    UNAUTHORIZED,   // 401/403
    NOT_FOUND,      // 404
    SERVER,         // 5xx
    SERIALIZATION,  // falha ao desserializar
    UNKNOWN,        // validação local / inesperado
}
```

### Helpers de transformação

```kotlin
inline fun <T, R> NetworkResult<T>.map(transform: (T) -> R): NetworkResult<R> =
    when (this) {
        is NetworkResult.Success -> NetworkResult.Success(transform(data))
        is NetworkResult.Error -> this
    }

inline fun <T> NetworkResult<T>.onSuccess(block: (T) -> Unit): NetworkResult<T> {
    if (this is NetworkResult.Success) block(data)
    return this
}

inline fun <T> NetworkResult<T>.onError(block: (ErrorType, String) -> Unit): NetworkResult<T> {
    if (this is NetworkResult.Error) block(type, message)
    return this
}
```

## safeApiCall — encapsula try/catch + mapeamento

Mora em `core/network/NetworkResult.kt`. Usado por toda implementação de repository.

```kotlin
import io.ktor.client.plugins.ClientRequestException
import io.ktor.client.plugins.ServerResponseException
import io.ktor.client.network.sockets.SocketTimeoutException
import io.ktor.http.HttpStatusCode
import kotlinx.serialization.SerializationException

suspend inline fun <T> safeApiCall(block: () -> T): NetworkResult<T> =
    try {
        NetworkResult.Success(block())
    } catch (e: ClientRequestException) {            // 4xx
        val type = when (e.response.status) {
            HttpStatusCode.Unauthorized, HttpStatusCode.Forbidden -> ErrorType.UNAUTHORIZED
            HttpStatusCode.NotFound -> ErrorType.NOT_FOUND
            else -> ErrorType.UNKNOWN
        }
        NetworkResult.Error(type, e.defaultMessage())
    } catch (e: ServerResponseException) {           // 5xx
        NetworkResult.Error(ErrorType.SERVER, "Erro no servidor. Tente novamente.")
    } catch (e: SocketTimeoutException) {
        NetworkResult.Error(ErrorType.NETWORK, "Tempo esgotado. Verifique sua conexão.")
    } catch (e: SerializationException) {
        NetworkResult.Error(ErrorType.SERIALIZATION, "Resposta inesperada do servidor.")
    } catch (e: Exception) {
        NetworkResult.Error(ErrorType.UNKNOWN, e.message ?: "Erro inesperado.")
    }

fun ErrorType.toUserMessage(): String = when (this) {
    ErrorType.NETWORK -> "Sem conexão com a internet."
    ErrorType.UNAUTHORIZED -> "Sessão expirada. Faça login novamente."
    ErrorType.NOT_FOUND -> "Não encontrado."
    ErrorType.SERVER -> "Erro no servidor. Tente mais tarde."
    ErrorType.SERIALIZATION -> "Resposta inválida do servidor."
    ErrorType.UNKNOWN -> "Algo deu errado."
}
```

> Tratamento avançado de exceções em corrotinas (`CoroutineExceptionHandler`, `SupervisorJob`,
> cancelamento) → skill **kotlin-coroutines**.

## Camadas: quem trata o quê

| Camada | Responsabilidade de erro |
|--------|--------------------------|
| `data` (repository) | Captura exceções com `safeApiCall`, devolve `NetworkResult.Error` com `ErrorType` |
| `domain` (usecase) | Valida regra de negócio → `NetworkResult.Error(UNKNOWN, "...")` antes de chamar o repo |
| `presentation` (ViewModel) | Converte `Error` em estado: `state.copy(error = ...)` ou `Effect.ShowError(...)` |
| UI | Apenas renderiza `error`/consome `Effect`. **Nunca** faz try/catch de I/O |

## Persistência (SQLDelight)

Erros de banco também passam por um wrapper. Para leituras reativas (`Flow`), use `.catch { }`:

```kotlin
fun observeUser(): Flow<User?> =
    local.observeUser()
        .map { it?.toDomain() }
        .catch { emit(null) }   // log + degrade graceful; não derruba o Flow
```

## Anti-padrões

- ❌ `try/catch` dentro de Composable/SwiftUI View.
- ❌ Lançar exceção do repository para o ViewModel.
- ❌ Expor `Throwable` no `UiState`.
- ❌ Engolir erro silenciosamente sem log nem feedback.
- ✅ Sempre `NetworkResult` na fronteira; mensagem amigável vinda de `ErrorType.toUserMessage()`.
