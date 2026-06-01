# api-contract-sync

> Sincroniza o contrato API entre Spring (springdoc OpenAPI) e Angular (interfaces TS).

Skill de implementação que regenera o client TypeScript a partir do OpenAPI do Spring e detecta divergências entre back e front. Compara antes/depois da pasta gerada, resume endpoints novos, schemas alterados e breaking changes, e lista arquivos do front que precisam de ajuste manual.

## Quando usar

- Regerar os tipos/client do front após mudança em DTOs ou Controllers do Spring
- Sincronizar API / atualizar contrato entre back e front
- Detectar breaking changes (opcional → obrigatório, renomeação de schema)
- Primeira configuração do `openapi-generator` no projeto Angular

## Conteúdo

- `SKILL.md` — pré-requisitos, fluxo de sincronização, heurísticas de breaking change e comandos típicos

## Relação com outras skills

Conecta `spring-boot-engineer` (produz o spec OpenAPI em `references/openapi.md`) e `angular-engineer` (consome o `libs/api-client` gerado). É o elo do contrato entre as duas skills de stack web, acionado na fase de implementação do fluxo SDD.
