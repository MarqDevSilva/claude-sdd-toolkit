# Convenções de Teste

Foco no que é compartilhado e tem mais valor: **use cases** e **ViewModels**. Testes ficam em
`shared/src/commonTest/` e rodam em todas as plataformas. Detalhes avançados de assíncrono
(`runTest`, `Turbine`, dispatchers de teste) → skill **kotlin-coroutines**.

## Onde os testes moram

```
shared/src/commonTest/kotlin/<pkg>/
├── auth/
│   ├── domain/usecase/LoginUseCaseTest.kt
│   ├── data/repository/AuthRepositoryImplTest.kt
│   └── presentation/login/LoginViewModelTest.kt
└── fakes/
    └── FakeAuthRepository.kt
```

## Pirâmide para este projeto

| Tipo | Cobertura | Ferramenta |
|------|-----------|------------|
| **Use case** | regra de negócio, validações, branches | `kotlin-test` + fake repository |
| **ViewModel** | transições de `UiState`, emissão de `Effect` | `runTest` + `Turbine` + fake use case |
| **Mapper** | DTO↔domain↔entity round-trip | `kotlin-test` puro |
| **Repository** | orquestração remote+local+map (com fakes/mock engine Ktor) | `runTest` + `MockEngine` do Ktor |
| UI (Compose/SwiftUI) | só fluxos críticos | nas skills de plataforma (android-expert / swiftui-*) |

## Fakes em vez de mocks

Preferimos **fakes** escritos à mão (sem libs de mock) — multiplataforma e legível.

```kotlin
// fakes/FakeAuthRepository.kt
class FakeAuthRepository(
    private var loginResult: NetworkResult<User> =
        NetworkResult.Success(User("1", "Ana", "ana@x.com")),
) : AuthRepository {
    var loginCalls = 0; private set
    fun programLogin(result: NetworkResult<User>) { loginResult = result }

    override suspend fun login(email: String, password: String): NetworkResult<User> {
        loginCalls++
        return loginResult
    }
    override suspend fun logout() {}
    override fun observeCurrentUser(): Flow<User?> = flowOf(null)
}
```

## Teste de use case

```kotlin
class LoginUseCaseTest {
    @Test
    fun `email invalido retorna erro sem chamar repository`() = runTest {
        val repo = FakeAuthRepository()
        val useCase = LoginUseCase(repo)

        val result = useCase("email-invalido", "123456")

        assertTrue(result is NetworkResult.Error)
        assertEquals(0, repo.loginCalls)
    }

    @Test
    fun `credenciais validas delegam ao repository`() = runTest {
        val repo = FakeAuthRepository()
        val useCase = LoginUseCase(repo)

        val result = useCase("ana@x.com", "123456")

        assertTrue(result is NetworkResult.Success)
        assertEquals(1, repo.loginCalls)
    }
}
```

## Teste de ViewModel (com Turbine)

```kotlin
class LoginViewModelTest {
    @Test
    fun `login com sucesso emite NavigateHome`() = runTest {
        val useCase = LoginUseCase(FakeAuthRepository())
        val vm = LoginViewModel(useCase)

        vm.onEvent(LoginEvent.EmailChanged("ana@x.com"))
        vm.onEvent(LoginEvent.PasswordChanged("123456"))

        vm.effect.test {
            vm.onEvent(LoginEvent.Submit)
            assertEquals(LoginEffect.NavigateHome, awaitItem())
        }
    }

    @Test
    fun `submit ativa e desativa isLoading`() = runTest {
        val vm = LoginViewModel(LoginUseCase(FakeAuthRepository()))
        vm.state.test {
            assertFalse(awaitItem().isLoading)         // estado inicial
            vm.onEvent(LoginEvent.Submit)
            assertTrue(awaitItem().isLoading)           // durante
            assertFalse(awaitItem().isLoading)          // depois
        }
    }
}
```

> Configure um `Dispatchers.setMain(StandardTestDispatcher())` / injete o dispatcher quando o ViewModel usar
> `viewModelScope`. Padrão de dispatcher injetável e `runTest` avançado → skill **kotlin-coroutines**.

## Teste de repository com Ktor MockEngine

```kotlin
@Test
fun `login mapeia DTO para domain e persiste`() = runTest {
    val engine = MockEngine { respond(
        content = """{"id":"1","name":"Ana","email":"ana@x.com"}""",
        headers = headersOf(HttpHeaders.ContentType, "application/json"),
    ) }
    val api = AuthApi(HttpClient(engine) { install(ContentNegotiation) { json() } }, ApiConfig("http://test"))
    val local = FakeAuthLocalDataSource()
    val repo = AuthRepositoryImpl(api, local)

    val result = repo.login("ana@x.com", "123456")

    assertEquals("Ana", (result as NetworkResult.Success).data.name)
    assertEquals(1, local.upsertCount)
}
```

## Convenções

| Item | Regra |
|------|-------|
| Nome do arquivo | `<TipoTestado>Test.kt` |
| Nome do método | crase, frase em PT-BR descrevendo comportamento |
| Estrutura | Arrange / Act / Assert (sem comentários se óbvio) |
| Dependências | fakes à mão em `commonTest/fakes/`; `MockEngine` para Ktor |
| Assíncrono | sempre `runTest { }`; nunca `Thread.sleep`/`runBlocking` em teste de unidade |
| O que NÃO testar aqui | navegação e renderização de UI → skills de plataforma |
