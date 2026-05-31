---
name: api-contract-sync
description: Sincroniza contrato API entre Spring (springdoc OpenAPI) e Angular (interfaces TS) — regera client TS e detecta divergências entre back e front.
---

# api-contract-sync

Use quando o usuário pedir pra **sincronizar API**, **regerar tipos do front**, **atualizar contrato** ou quando houve mudança em DTOs/Controllers no Spring que precisam refletir no Angular.

## Pré-requisitos

- Spring com `springdoc-openapi` configurado e endpoint `/v3/api-docs` acessível (ou OpenAPI exportado em arquivo).
- Angular consumindo client gerado por `openapi-generator` (ou similar). Identificar configuração:
  - Pasta `src/app/api/generated/` ou similar.
  - Script no `package.json` (ex: `"api:gen": "openapi-generator-cli generate ..."`).

## O que faz

1. Verifica configuração:
   - Pergunta URL ou caminho do OpenAPI atual.
   - Pergunta diretório de saída do client TS.
   - Pergunta script de geração (se já existir).
2. Se for primeira execução:
   - Sugere instalação de `@openapitools/openapi-generator-cli`.
   - Cria `openapi-generator-config.yaml` mínimo.
   - Sugere script `npm run api:gen` no `package.json`.
3. Roda regeração (ou monta o comando pro usuário rodar).
4. Compara antes/depois (`git diff` da pasta gerada) e resume mudanças:
   - Endpoints novos
   - Schemas alterados (campos adicionados, removidos, tipo mudado)
   - Breaking changes potenciais
5. Verifica usos no front:
   - Faz `grep` por DTOs/operations removidos ou renomeados.
   - Lista arquivos que precisam de ajuste manual.

## Heurísticas

- **Nunca** editar manualmente arquivos da pasta gerada — todo ajuste tem que vir do Spring.
- **Versionar** a pasta gerada (commit) pra que diffs apareçam em PR review.
- Mudança de campo obrigatório → opcional? OK, retro-compatível.
- Mudança de opcional → obrigatório? Breaking — exigir versão `/v2` ou plano de migração.
- Renomeação de schema? Breaking — exigir alias ou versão nova.

## Comandos típicos

```bash
# regenerar client TS (Angular)
npx @openapitools/openapi-generator-cli generate \
  -i http://localhost:8080/v3/api-docs \
  -g typescript-angular \
  -o src/app/api/generated \
  --additional-properties=ngVersion=18.0.0,providedInRoot=true
```

## Como invocar

```
/api-contract-sync
```

## Saída

- Status (sincronizado / havia divergências / mudanças aplicadas).
- Lista de arquivos do front que podem precisar ajuste manual.
- Sugestão de testes de contrato a rodar se o projeto tem.
