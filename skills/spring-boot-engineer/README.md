# spring-boot-engineer

> Gera aplicações Spring Boot 3.x como monolito organizado por bounded context.

Skill de implementação backend. Produz features REST em camadas (`api`/`domain`/`application`/`infra`), fluxos de autenticação com Spring Security 6, repositórios Spring Data JPA, além de error handling padronizado, contrato OpenAPI e observabilidade via Actuator.

## Quando usar

- Estruturar um monolito Spring Boot por bounded context
- Criar features REST em camadas (api/domain/application/infra)
- Configurar Spring Security 6 e fluxos de autenticação
- Mapear entidades e repositórios com Spring Data JPA
- Padronizar error handling, OpenAPI e observabilidade

## Conteúdo

- `SKILL.md` — workflow, package structure e padrões core
- `references/web.md` — camada REST / controllers e DTOs
- `references/data.md` — Spring Data JPA e persistência
- `references/security.md` — Spring Security 6 e autenticação
- `references/error-handling.md` — ErrorCode, exceptions e GlobalExceptionHandler
- `references/openapi.md` — springdoc OpenAPI e contrato de erro
- `references/observability.md` — Actuator, health e métricas
- `references/testing.md` — testes unit, integração e slice

## Relação com outras skills

`spring-boot-engineer` + `angular-engineer` são as skills de stack web; `api-contract-sync` consome o OpenAPI gerado aqui (`references/openapi.md`) para sincronizar o front. Acionadas na fase de implementação do fluxo SDD.
