# ui-blueprint

Planeja e constrói as **telas de um app** cruzando os **módulos de discovery** (`.spec/discovery/module_*.md`) com os **domains do Angular** (`libs/domains/src/lib/*`). Produz um blueprint revisável (escopo, áreas → páginas, navegação, shell) e uma **fila de specs, uma por página**, depois drena a fila construindo cada tela **junto com o usuário** via `angular-engineer`.

É o elo do ecossistema SDD:

```
app-kickoff → módulos        api-contract-sync → domains
                     \             /
                   ui-blueprint (cruza → telas + fila de specs)
                            ↓
                  angular-engineer (constrói cada página)
```

## Arquivos

- `SKILL.md` — fluxo completo (pré-requisitos, Fase 0 blueprint, Fase 1 drain, regras de mapeamento, política de drift).
- `references/blueprint.template.md` — formato do `.spec/discovery/<app>-blueprint.md`.
- `references/screen-spec.template.md` — formato da spec por página (`.spec/changes/UI-<NNN>-<slug>/spec.md`), estende o template SDD com a seção "Contrato de UI".
- `scripts/index-domains.mjs` — índice factual dos domains (recurso, métodos, models) pro agente não ler dezenas de pastas.

## Uso

```bash
# Fase 0a — índice factual (sem LLM)
node skills/ui-blueprint/scripts/index-domains.mjs \
  --domains-root frontend/libs/domains/src/lib \
  --out .spec/discovery/_domain-index.md
```

Depois invoque `/ui-blueprint`: o agente lê os módulos + o índice, escreve o blueprint pra você revisar, emite a fila de specs por página, e drena uma página por vez (use `/loop` pra encadear).

## Princípios

- **Tela = área/jornada**, compõe 1..N domains. Nunca 1 tela por domain.
- **Módulos = fonte de verdade do escopo**; domain é o "como".
- **1 spec = 1 página.**
- **Fase 0 é agente + revisão humana** (julgamento de UX); **Fase 1 é colaborativa, com gates** (não headless).
- Shell + UI lib são **pré-requisito idempotente** (scaffold 1×).
