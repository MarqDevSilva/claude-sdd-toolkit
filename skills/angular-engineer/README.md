# angular-engineer

> Gera aplicações Angular 18+ num monorepo nativo do Angular CLI (apps + libs), organizado por bounded contexts.

Skill de implementação frontend. Produz código com standalone components, estado baseado em signals e **services inteligentes** por domínio (injetam `HttpClient`, falam com o backend e sincronizam o state), pages/layouts/components organizados por área, tratamento de erro com `ProblemDetails` (RFC 7807), além de setup de ESLint/Prettier e testes com Jasmine/TestBed. **Não há client OpenAPI gerado** — os domains chamam `HttpClient` direto.

## Quando usar

- Estruturar um monorepo Angular (apps + libs por domínio)
- Implementar state com signals + service inteligente por bounded context
- Consumir a API via `HttpClient` + token `API_BASE_URL`, com erro padronizado em `ProblemDetails`
- Padronizar lint/format (ESLint flat config + Prettier)
- Escrever testes de service com `HttpTestingController` e de componente/unidade com TestBed

## Conteúdo

- `SKILL.md` — workflow, estrutura do monorepo e padrões core
- `references/http-services.md` — `HttpClient`, token `API_BASE_URL`, `ProblemDetails`, interceptors
- `references/components.md` — smart pages/layouts/components e UI reutilizável
- `references/state-management.md` — signals container + service inteligente por domínio
- `references/lint-format.md` — ESLint/Prettier
- `references/testing.md` — Jasmine/TestBed + HttpTestingController

## Relação com outras skills

`angular-engineer` + `spring-boot-engineer` são as skills de stack web; `api-contract-sync` lê o OpenAPI do Spring e **constrói os domains** (model + state + service + spec) seguindo o padrão desta skill. Todas são acionadas na fase de implementação do fluxo SDD.
