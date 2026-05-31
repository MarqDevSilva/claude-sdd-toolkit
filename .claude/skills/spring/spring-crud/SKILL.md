---
name: spring-crud
description: Gera CRUD completo Spring Boot — Entity JPA, Repository, Service, Controller REST, DTOs (records), Mapper MapStruct e migration Flyway pra um recurso.
---

# spring-crud

Use quando o usuário pedir pra **criar CRUD**, **scaffold de recurso REST**, **endpoints básicos** para uma entidade.

## Pré-requisitos

- Projeto Spring Boot 3.3+ com JPA, Flyway, MapStruct, springdoc-openapi configurados.
- `.spec/memory/conventions.md` lida — segue layout por feature.

## O que faz

Pergunta:
- Nome do recurso (singular, PascalCase para classe): ex `Invoice`.
- Pacote raiz da feature: ex `com.app.invoice`.
- Campos da entidade (nome + tipo + obrigatório?).
- Tem relacionamentos? (1:N, N:N)
- Endpoints desejados (default: GET list paginado, GET by id, POST, PUT, DELETE).

Cria a árvore:

```
<feature>/
├── api/
│   ├── <Recurso>Controller.java
│   ├── dto/
│   │   ├── <Recurso>Request.java                       (record)
│   │   └── <Recurso>Response.java                      (record)
│   └── mapper/
│       └── <Recurso>Mapper.java                        (interface MapStruct)
├── domain/
│   ├── model/
│   │   └── <Recurso>.java                              (@Entity)
│   ├── service/                                        (vazio inicialmente)
│   └── exception/
│       ├── <Recurso>NaoEncontradoException.java
│       └── <Recurso>DuplicadoException.java            (se houver unique)
├── application/
│   └── <Recurso>Service.java
└── infra/
    └── <Recurso>Repository.java                        (extends JpaRepository)
```

> **Sobre `domain/service/`**: o CRUD básico **não** cria Domain Service. Crie só quando aparecer uma regra que cruza entidades (ex: "cliente bloqueado não pode criar fatura"). Regras que pertencem a uma entidade só (ex: "fatura paga não pode ser cancelada") vão **dentro** da entity em `model/`.

E uma migration Flyway: `db/migration/V<timestamp>__create_<recurso>.sql`.

## Convenções aplicadas

- **Entity** usa `@Entity`, ID `UUID` (gerado pela app, não pelo BD), campos `Instant criadoEm`/`atualizadoEm` com `@CreatedDate`/`@LastModifiedDate`.
- **Controller** usa `@RestController` + `@RequestMapping("/api/v1/<recursos>")`, paginação com `Pageable`, retorna `ResponseEntity<>` com `Location` em POST.
- **DTOs** são `record`s. Validação com Jakarta (`@NotBlank`, `@Size`, `@Email`).
- **Service** anotado com `@Service` e `@Transactional` (readOnly = true por padrão; método de escrita sobrescreve).
- **Repository** é interface que estende `JpaRepository<Entity, UUID>`.
- **Mapper** MapStruct com `@Mapper(componentModel = "spring")`.
- **Exceptions de domínio** estendem `DomainException` (em `shared/error/`) e carregam um `ErrorCode` central. Para cada nova exception, gerar **3 mudanças coordenadas**:
  1. Nova entrada no enum `ErrorCode` (em `shared/error/ErrorCode.java`).
  2. Nova chave em `src/main/resources/messages.properties` (e em outros locales se já existirem).
  3. Classe da exception na feature, estendendo `DomainException`.
- O `@RestControllerAdvice` global e a config de `MessageSource` já existem em `shared/error/` e `config/` — o skill **não** recria. Se não existirem ainda, ver [.spec/shared/error-handling.md](../../../../.spec/shared/error-handling.md) pra setup inicial.
- Migration cria tabela + índices necessários + constraints.

## Snippet de Controller

```java
@RestController
@RequestMapping("/api/v1/<recursos>")
@RequiredArgsConstructor
public class <Recurso>Controller {

    private final <Recurso>Service service;
    private final <Recurso>Mapper mapper;

    @PostMapping
    public ResponseEntity<<Recurso>Response> criar(@Valid @RequestBody <Recurso>Request req) {
        var criado = service.criar(mapper.toEntity(req));
        var location = ServletUriComponentsBuilder.fromCurrentRequest()
            .path("/{id}").buildAndExpand(criado.getId()).toUri();
        return ResponseEntity.created(location).body(mapper.toResponse(criado));
    }

    @GetMapping("/{id}")
    public <Recurso>Response porId(@PathVariable UUID id) {
        return mapper.toResponse(service.buscarPorId(id));
    }

    @GetMapping
    public Page<<Recurso>Response> listar(Pageable pageable) {
        return service.listar(pageable).map(mapper::toResponse);
    }
}
```

## Como invocar

```
/spring-crud
/spring-crud Invoice em com.app.invoice
```

## Saída

- Lista de arquivos criados.
- Lembrete pra checar `@RestControllerAdvice` global e config de Spring Data envers (audit) se aplicável.
- Sugestão: rodar `/spring-test` em seguida pra cobrir os testes do CRUD gerado.
