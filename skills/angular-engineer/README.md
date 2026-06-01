# angular-engineer

> Gera aplicações Angular 18+ num monorepo nativo do Angular CLI (apps + libs), organizado por bounded contexts.

Skill de implementação frontend. Produz código com standalone components, estado baseado em signals e facades por domínio, pages/layouts/components organizados por área, consumo do client OpenAPI gerado, além de setup de ESLint/Prettier e testes com Jasmine/TestBed.

## Quando usar

- Estruturar um monorepo Angular (apps + libs por domínio)
- Implementar state com signals + facade por bounded context
- Consumir o `libs/api-client` gerado a partir do OpenAPI
- Padronizar lint/format (ESLint flat config + Prettier)
- Escrever testes de componente/unidade com TestBed

## Conteúdo

- `SKILL.md` — workflow, estrutura do monorepo e padrões core
- `references/api-client.md` — consumo do client OpenAPI gerado
- `references/components.md` — smart pages/layouts/components e UI reutilizável
- `references/state-management.md` — signal store + facade por domínio
- `references/lint-format.md` — ESLint/Prettier
- `references/testing.md` — Jasmine/TestBed

## Relação com outras skills

`angular-engineer` + `spring-boot-engineer` são as skills de stack web; `api-contract-sync` conecta o contrato OpenAPI entre back e front. Todas são acionadas na fase de implementação do fluxo SDD.
