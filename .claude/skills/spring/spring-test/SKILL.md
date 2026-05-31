---
name: spring-test
description: Escreve testes Spring (JUnit 5 + AssertJ + Spring Test): unit puro, slice tests (@WebMvcTest, @DataJpaTest) e integração com Testcontainers.
---

# spring-test

Use quando o usuário pedir pra **testar service**, **testar controller**, **testar repository**, **cobrir testes** de código Spring.

## Pré-requisitos

- Projeto Spring Boot 3.3+ com JUnit 5, AssertJ e Testcontainers configurados.
- Convenções em `.spec/memory/conventions.md`.

## Estratégia de teste por camada

| Camada | Tipo de teste | Anotações |
|--------|---------------|-----------|
| `domain` (regras puras) | Unit puro (sem Spring) | nenhuma |
| `application.Service` | Unit + mocks (Mockito) | `@ExtendWith(MockitoExtension.class)` |
| `infra.Repository` | Slice JPA | `@DataJpaTest` |
| `api.Controller` | Slice Web | `@WebMvcTest` |
| Fluxo ponta-a-ponta | Integração | `@SpringBootTest` + `@Testcontainers` |

## O que faz

1. Identifica camada do arquivo a testar.
2. Lê o arquivo + dependências.
3. Cria `<arquivo>Test.java` em `src/test/java/...` espelhando o pacote.
4. Aplica padrões por camada.

## Padrões

### Domain (unit puro)

```java
class InvoiceTest {

    @Test
    void naoPermiteValorNegativo() {
        assertThatThrownBy(() -> new Invoice(BigDecimal.valueOf(-1)))
            .isInstanceOf(InvoiceInvalidaException.class)
            .hasMessageContaining("valor");
    }
}
```

### Service (unit + mocks)

```java
@ExtendWith(MockitoExtension.class)
class InvoiceServiceTest {

    @Mock InvoiceRepository repository;
    @InjectMocks InvoiceService service;

    @Test
    void buscarPorId_lancaQuandoNaoEncontrado() {
        when(repository.findById(any())).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.buscarPorId(UUID.randomUUID()))
            .isInstanceOf(InvoiceNaoEncontradaException.class);
    }
}
```

### Repository (`@DataJpaTest`)

- Usa Testcontainers Postgres se o projeto suporta, em vez do H2 (que diverge do dialeto real).
- Foca em queries customizadas e relacionamentos, **não** em métodos default do `JpaRepository`.

### Controller (`@WebMvcTest`)

```java
@WebMvcTest(InvoiceController.class)
class InvoiceControllerTest {

    @Autowired MockMvc mockMvc;
    @MockBean InvoiceService service;

    @Test
    void post_201_quandoCriado() throws Exception {
        when(service.criar(any())).thenReturn(invoiceMock());

        mockMvc.perform(post("/api/v1/invoices")
                .contentType(APPLICATION_JSON)
                .content("""
                    {"valor": 100.00}
                """))
            .andExpect(status().isCreated())
            .andExpect(header().exists("Location"));
    }
}
```

### Integração (`@SpringBootTest` + Testcontainers)

- Só pros fluxos críticos onde valor agregado justifica o tempo de execução.
- Usa Postgres em container compartilhado entre testes (`@Container` static).
- Limpa estado por teste com `@Transactional` + rollback ou TRUNCATE explícito.

## Heurísticas

- **Slice antes de integração.** `@SpringBootTest` é caro.
- **Não usar H2** quando produção é Postgres. Testcontainers é a fronteira aceitável.
- **Sem `@MockBean` em domain test** — domain não deve precisar de Spring.
- Mensagens de assert claras (`assertThat(...).as("descrição")`).

## Como invocar

```
/spring-test
/spring-test src/main/java/com/app/invoice/application/InvoiceService.java
```

## Saída

- Arquivo de teste criado/atualizado.
- Resumo dos casos cobertos.
- Aviso se identificar comportamento sem cobertura.
