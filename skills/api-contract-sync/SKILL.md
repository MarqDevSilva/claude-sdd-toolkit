---
name: api-contract-sync
description: Lê o OpenAPI do Spring (springdoc, /v3/api-docs) e constrói/sincroniza os domains do Angular (model + state + service + spec) diretamente, sem gerador de client. Um agente mapeia tags→domains, schemas→interfaces e operations→métodos de service sobre HttpClient, seguindo o padrão do angular-engineer, e detecta breaking changes entre back e front.
---

# api-contract-sync

Use quando o usuário pedir pra **sincronizar API**, **regerar os domains do front**, **atualizar contrato** ou quando houve mudança em DTOs/Controllers no Spring que precisa refletir no Angular.

> **Mudou (v2):** não usamos mais `openapi-generator` / `libs/api-client`. Em vez de gerar um client verboso, um **agente** lê o spec OpenAPI do Spring e **constrói os domains diretamente** — `model.ts` + `state.ts` + `service.ts` + `service.spec.ts` — no padrão de `angular-engineer` (signals + service inteligente sobre `HttpClient`). Ver `angular-engineer/SKILL.md` e `angular-engineer/references/http-services.md`.

## Pré-requisitos

- Spring com `springdoc-openapi` configurado e endpoint `/v3/api-docs` acessível (ou OpenAPI exportado em arquivo JSON/YAML).
  - **Configuração do backend** (springdoc, annotations, contrato de erro `ProblemDetails`): ver `spring-boot-engineer/references/openapi.md`. Esta skill assume o spec já produzido e cuida só de construir/sincronizar o front.
- Monorepo Angular no padrão `angular-engineer`: domains em `libs/domains/<context>`, token `API_BASE_URL` em `libs/core`, `ProblemDetails`/`toProblemDetails` em `libs/shared/util`.
- Environments definidos por app (`environment.ts` = dev, `environment.hom.ts`, `environment.prod.ts`), cada um com `apiUrl`.

## Estratégia: nenhum agente lê o api-docs inteiro

O api-docs do springdoc costuma ter **milhares de linhas e dezenas de tags**. Pôr o arquivo todo na frente de um agente é o que causa alucinação/omissão — não pelo volume de tokens, mas porque ele tem que *escolher* o que é relevante. A solução separa o **mecânico** (não passa por LLM) da **geração** (passa):

1. **Fase 0 — Fatiar (script determinístico).** [scripts/slice-openapi.mjs](scripts/slice-openapi.mjs) parseia o OpenAPI e, **por tag**, escreve uma `.spec/changes/SPEC-<NNN>-<slug>/spec.md` contendo só as operations daquela tag + o **fecho transitivo dos schemas** (`$ref`) que elas referenciam. Cada fatia tem algumas centenas de linhas, é auto-contida, e a lista de endpoints/schemas é **fato** (parsing puro), não interpretação.
2. **Fase 1 — Drenar a fila (agente, self-driving).** O agente processa **uma spec por vez** da fila `.spec/changes/`, constrói o domain, **verifica** (contagens), **arquiva** a spec em `.spec/archive/` e segue pra próxima — sem o usuário acionar cada agente. Cada agente vê **uma** fatia pequena, nunca o api-docs.

Assim a tarefa de cada agente é concreta e verificável, e o controle do que foi feito fica na trilha `changes/ → archive/`.

## O que faz

1. **Localiza o contrato e a estrutura**
   - Pergunta a URL ou caminho do OpenAPI (`http://localhost:8080/v3/api-docs` ou arquivo JSON).
   - Confirma a raiz dos domains (`libs/domains/`) e os environments do(s) app(s).
2. **Roda o script de fatiamento** (Fase 0) → gera a fila de specs em `.spec/changes/`, uma por tag.
3. **Drena a fila** (Fase 1) — para cada spec, em ordem de `SPEC-<NNN>`:
   - Lê **só** aquela `spec.md` (operations + fatia OpenAPI embutida).
   - Constrói/sincroniza o domain conforme `operacao` (`scaffold` | `sync`) e as regras de mapeamento.
   - **Verifica** as contagens (nº de interfaces == schemas; nº de métodos == operations).
   - Move a pasta `SPEC-<NNN>-<slug>/` pra `.spec/archive/` e marca `status: concluida`.
   - Segue automaticamente pra próxima spec.
4. **Garante os environments e o token**: confere `apiUrl` em dev/hom/prod e o provider `API_BASE_URL` no `app.config.ts`.
5. **Reporta drift e breaking changes**: em domains que já existem (`operacao: sync`), não sobrescreve service/state — lista o que mudou no contrato pro dev aplicar à mão.

## Regras de mapeamento OpenAPI → Angular

Um **agente** aplica estas regras de forma determinística (uma rodada por domain; pode paralelizar com subagents por tag):

### Tag → domain
- Cada `tag` do OpenAPI vira uma pasta `libs/domains/<tag-kebab>/`.
- Operations sem tag → agrupar pela primeira parte do path (`/categorias/...` → `categoria`). Confirmar com o usuário se ambíguo.

### Schema → interface (`<domain>.model.ts`)
Interfaces **1:1** com `components.schemas`, sem ViewModel/mapper. Mapa de tipos:

| OpenAPI | TypeScript |
|---------|-----------|
| `string` | `string` |
| `string` + `format: date-time`/`date` | `string` (ISO) |
| `string` + `enum: [A, B]` | `'A' \| 'B'` (union literal) |
| `integer` / `number` | `number` |
| `boolean` | `boolean` |
| `array` (`items`) | `T[]` |
| `$ref: '#/.../Foo'` | `Foo` (importa do mesmo model) |
| `object` (inline) | interface aninhada nomeada |
| `nullable: true` | `\| null` |
| campo fora de `required` | propriedade opcional `?` |

- Nome da interface = nome do schema (`CategoriaResponse`, `CriarCategoriaRequest`). Mantém os nomes do back (fazem parte do contrato).
- `*.model.ts` é **sempre regenerado** (é seguro — não tem lógica). Nunca editar à mão.

### Operation → método de service (`<domain>.service.ts`)
- Nome do método = `operationId` em camelCase, **removendo sufixos de desambiguação do springdoc** (`buscarPorId_2` → `buscarPorId`, `atualizar_10` → `atualizar`). Na ausência de `operationId`, derivar `<verbo><Recurso>` do path. Se a limpeza gerar colisão, manter o nome mais específico e reportar.
- Verbo HTTP → `this.http.get/post/put/patch/delete<T>(...)`.
- Path com `{id}` → template string interpolando o parâmetro; query params → `HttpParams`.
- `requestBody` → tipado com a interface de request; resposta → tipada com a interface de response.
- Todo método segue o esqueleto do padrão: `iniciarCarregamento()` → `http.<verbo>(...)` → `.pipe(tap(muta state), catchError(handleError))` → retorna o `Observable`.
- `handleError` único por service mapeando `HttpErrorResponse` → `ProblemDetails` em `state.erro`.
- `baseUrl = \`${inject(API_BASE_URL)}/<recurso>\`` — **nunca** importar `environment` num lib domain. O `<recurso>` vem do **path real das operations** (ex.: tag `Categorias` mas paths `/categories` → `baseUrl` usa `/categories`), não do slug do domain.

### State (`<domain>.state.ts`)
- Container de signals públicos graváveis (sem `asReadonly`/métodos). Baseline scaffold:
  - lista do recurso (`itens` / `raizes`), `selecionado`, `carregando: signal(false)`, `erro: signal<ProblemDetails | null>(null)`.
- O agente gera um baseline sensato; ajustes de modelagem de estado (caches, índices, cascata) ficam por conta do dev.

### Spec (`<domain>.service.spec.ts`)
- Gerado para cada domain **novo**, com `HttpTestingController`: cobre o CRUD básico (método/URL/body + mutação do state + erro→ProblemDetails). Ver `angular-engineer/references/testing.md`.

### Barrel (`index.ts`)
```typescript
export * from './<domain>.model';
export * from './<domain>.service';
export * from './<domain>.state';
```

## Política de regeração

Ao re-sincronizar um domain que já existe:

| Arquivo | Ação |
|---------|------|
| `<domain>.model.ts` | **Sempre regenerado** a partir do schema (seguro, sem lógica) |
| `<domain>.state.ts` | **Scaffold 1x**: cria se não existir; se existir, **não sobrescreve** — reporta se o contrato sugere novos campos |
| `<domain>.service.ts` | **Scaffold 1x**: cria se não existir; se existir, **não sobrescreve** lógica custom (cache, cascata, otimista) — reporta drift (operations novas/removidas/alteradas) pro dev aplicar |
| `<domain>.service.spec.ts` | Gerado só pra domain **novo**; em domain existente, não sobrescreve |

> O ponto-chave: lógica custom de domínio (ex.: cache de filhos, invalidação em cascata) **não é derivável do OpenAPI**. Por isso `service`/`state` são scaffolded uma vez e depois pertencem ao dev; só os `model` acompanham o contrato automaticamente.

## Environments

- Conferir/criar `environment.ts` (dev), `environment.hom.ts`, `environment.prod.ts`, cada um com `apiUrl` apontando pro backend daquele ambiente.
- Conferir o provider no `app.config.ts`: `{ provide: API_BASE_URL, useValue: environment.apiUrl }`.
- Conferir `fileReplacements` no `angular.json` pras builds `hom`/`prod`.

## Heurísticas de breaking change

- Campo obrigatório → opcional? **OK**, retro-compatível.
- Campo opcional → obrigatório? **Breaking** — exigir versão `/v2` ou plano de migração.
- Renomeação de schema/campo? **Breaking** — exigir alias ou versão nova; reportar usos no front.
- Operation removida/renomeada? `grep` pelos métodos do service afetados e listar arquivos pra ajuste manual.
- Mudança de tipo (ex.: `string` → `number`)? **Breaking** no model regenerado — compilação do front vai acusar; listar os consumidores.

## Como invocar

```
/api-contract-sync
```

### Fase 0 — Fatiar o contrato na fila

```bash
# confira primeiro com --dry-run (não escreve nada)
node skills/api-contract-sync/scripts/slice-openapi.mjs \
  --input http://localhost:8080/v3/api-docs \
  --spec-root ./.spec --domains-root libs/domains --dry-run

# gera a fila .spec/changes/SPEC-<NNN>-<slug>/spec.md (uma por tag)
node skills/api-contract-sync/scripts/slice-openapi.mjs \
  --input ./temp/api-docs.json --spec-root ./.spec --domains-root libs/domains
```

> Aceita só JSON (se o spec for YAML, exporte como JSON antes). `--only <tag>` fatia uma tag só;
> `--force` regera specs já existentes; `--author`/`--date` ajustam o frontmatter. Se a skill estiver
> instalada em `.claude/skills/`, ajuste o caminho do script.

### Fase 1 — Drenar a fila (self-driving)

O agente repete, **sem o usuário acionar cada passo**, até a fila esvaziar:

1. Pega a próxima `spec.md` em `.spec/changes/` (menor `SPEC-<NNN>`).
2. Lê **só** essa spec (operations + fatia OpenAPI embutida).
3. Constrói/sincroniza o domain conforme `operacao` e as regras de mapeamento.
4. Roda a **verificação** da seção 4 da spec (contagens) + `ng lint`/`ng test` no domain.
5. Move `SPEC-<NNN>-<slug>/` pra `.spec/archive/` com `status: concluida`.
6. Volta ao passo 1.

> Para drenar a fila ao longo de várias sessões (ou pra dar pausa entre domains), envolva com
> `/loop` (self-paced): cada iteração processa e arquiva uma spec, e o loop segue sozinho.

## Saída

- Resumo da Fase 0: nº de specs geradas na fila (e quais foram puladas por já existirem).
- Por domain drenado: criado (model+state+service+spec) vs sincronizado (só model + drift report).
- **Drift report**: services/states existentes cujo contrato mudou e precisam de ajuste manual (não sobrescritos).
- Breaking changes detectadas e plano sugerido.
- Fila restante em `.spec/changes/` (se a execução foi pausada) e specs arquivadas em `.spec/archive/`.
