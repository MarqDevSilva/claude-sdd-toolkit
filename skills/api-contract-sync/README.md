# api-contract-sync

> Lê o OpenAPI do Spring e **constrói os domains do Angular** (model + state + service + spec), sem gerador de client.

Skill de implementação que sincroniza o contrato API entre back e front, mapeando **tags → domains**, **schemas → interfaces** e **operations → métodos de service** sobre `HttpClient`, no padrão de `angular-engineer` (signals + service inteligente, `ProblemDetails`, token `API_BASE_URL`).

Para não pôr um api-docs de milhares de linhas na frente de um agente (risco de alucinação/omissão), o fluxo é em duas fases:

1. **Fatiar (script determinístico)** — `scripts/slice-openapi.mjs` gera, por tag, uma `.spec/changes/SPEC-<NNN>-<slug>/spec.md` auto-contida com as operations + o **fecho transitivo dos schemas** (`$ref`). Algumas centenas de linhas por fatia, e a lista de endpoints/schemas é fato (parsing puro).
2. **Drenar a fila (agente, self-driving)** — processa uma spec por vez, constrói o domain, verifica contagens, **arquiva** a spec em `.spec/archive/` e segue sozinho pra próxima.

Detecta endpoints novos, schemas alterados e breaking changes, e reporta drift sem sobrescrever lógica custom.

> **Mudou (v2):** saiu o `openapi-generator` / `libs/api-client` (verboso). Entrou a construção direta dos domains pelo agente, no padrão do projeto.

## Quando usar

- Construir/sincronizar os domains do front a partir do OpenAPI do Spring
- Regerar os `*.model.ts` após mudança em DTOs ou Controllers
- Detectar breaking changes (opcional → obrigatório, renomeação de schema, mudança de tipo)
- Conferir environments (dev/hom/prod) e o wiring do token `API_BASE_URL`

## Conteúdo

- `SKILL.md` — estratégia (fatiar → drenar), regras de mapeamento OpenAPI→Angular, política de regeração (models sempre; service/state scaffold 1x + drift), environments e heurísticas de breaking change
- `scripts/slice-openapi.mjs` — fatia o api-docs em uma spec por tag, com o fecho transitivo de `$ref` embutido (Node, sem dependências; `--dry-run`, `--only`, `--force`)

## Relação com outras skills

Conecta `spring-boot-engineer` (produz o spec OpenAPI + contrato de erro `ProblemDetails` em `references/openapi.md`) e `angular-engineer` (define o padrão de domain: state com signals + service sobre `HttpClient`). É o elo do contrato entre as duas skills de stack web, acionado na fase de implementação do fluxo SDD.
