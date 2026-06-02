---
name: ui-blueprint
description: Cruza os módulos de discovery (.spec/discovery/module_*.md) com os domains do Angular (libs/domains) para inferir o mapa de telas de um app — escopo por persona, áreas → páginas, árvore de navegação e proposta de shell/layout — e emite uma spec POR PÁGINA na fila .spec/changes/. Depois drena a fila construindo cada tela JUNTO com o usuário via angular-engineer. Use para planejar e ir implementando as telas de um portal/app a partir do que o backend já expõe.
license: MIT
metadata:
  version: "1.0.0"
  domain: frontend
  triggers: mapear telas, blueprint do portal, mapa de telas, screen map, árvore de navegação, montar o shell, construir as telas, planejar UI, ui-blueprint
  role: specialist
  scope: planning+implementation
  output-format: spec+code
  related-skills: app-kickoff, api-contract-sync, angular-engineer, spec-new
---

# ui-blueprint

Use quando o usuário quiser **mapear/planejar as telas** de um app, **gerar o mapa de áreas + navegação + shell**, ou **ir construindo as telas** de um portal a partir dos domains que o backend já expõe. Triggers: "mapear as telas do portal", "blueprint do fornecedor", "mapa de telas", "monta o shell", "vamos construindo as telas", `/ui-blueprint`.

> **A ideia central:** tela **não é** domain. No padrão `angular-engineer`, **página = área/jornada** que compõe 1..N domains. E nem todo domain pertence a um app específico — cada app é uma **persona** (cliente, fornecedor, franqueado, adm) e usa só um subconjunto. Esta skill faz o cruzamento **módulo × domain → telas** e transforma isso numa fila de implementação, uma spec por página.

## Onde encaixa no ecossistema

Esta skill é o **elo** entre o que o discovery e o contract-sync já produziram e o que o `angular-engineer` constrói. Ela não substitui `spec-new`/`angular-engineer` — ela os **orquestra**.

```
app-kickoff        → módulos / entities / roadmap   (.spec/discovery/module_*.md)
api-contract-sync  → domains do backend             (libs/domains/src/lib/*)
        └── ui-blueprint → cruza módulos × domains → blueprint + fila de specs de tela
                              → angular-engineer constrói cada página (spec-*  p/ o ciclo SDD)
```

## Pré-requisitos

1. **Domains construídos** — `libs/domains/src/lib/<dominio>/` com `model.ts` + `state.ts` + `service.ts` (rode `api-contract-sync` antes). São o "como" técnico de cada tela.
2. **Módulos de discovery** — `.spec/discovery/module_<nome>.md` no formato do `app-kickoff` (atores, RFs, regras, fluxos). São a **fonte de verdade do escopo** — o que entra em cada app e a prioridade. Sem eles, a skill pergunta o escopo em vez de adivinhar.
3. **App alvo** — qual app/persona (`apps/<app>`). Se o app ainda não existe, gere com `ng generate application <app> --ssr --style=scss --prefix=hf --routing`.
4. **Padrão de build** — `angular-engineer` (signals + smart service + ProblemDetails) e as convenções in-repo (`.spec/memory/architecture.md`, `.spec/memory/conventions.md`, `README` do front). A UI lib do projeto e o tema vêm do README do front.

## Estratégia: o blueprint é o backbone; specs por página são a fila

Espelha o que funcionou no `api-contract-sync`: **separar o factual do julgamento**, e nunca pôr "tudo" na frente de um agente.

1. **Fase 0a — Indexar domains (script determinístico).** [scripts/index-domains.mjs](scripts/index-domains.mjs) varre `libs/domains/src/lib/*` e escreve `.spec/discovery/_domain-index.md`: por domain, o **recurso** (`baseUrl`), os **métodos públicos** do service e as **interfaces** do model. É *fato* (parsing), não interpretação — e dá ao agente um índice compacto em vez de 43 pastas.
2. **Fase 0b — Blueprint (agente + revisão humana).** O agente lê **os módulos + o índice de domains** (não o código todo) e produz `.spec/discovery/<app>-blueprint.md`: escopo, mapa de áreas → páginas, navegação e proposta de shell. **O usuário revisa e ajusta** — agrupar em áreas é julgamento de UX, por isso aqui é agente, não script.
3. **Fase 0c — Emitir a fila.** Aprovado o blueprint, a skill gera **uma spec por página** em `.spec/changes/UI-<NNN>-<slug>/spec.md` (template auto-preenchido).
4. **Fase 1 — Drain colaborativo.** Pega a próxima spec, constrói a página **junto com o usuário** via `angular-engineer`, testa, roda no browser, arquiva em `.spec/archive/` e segue. **Uma por vez, com gates** — diferente do contract-sync (headless/paralelo), porque telas têm julgamento de UX e o usuário quer construir junto.

## Fase 0 — Blueprint

1. **Confirma o app/persona** e a raiz dos módulos.
2. Roda o índice de domains (Fase 0a).
3. Um agente cruza **módulos × índice** e escreve o blueprint (ver [references/blueprint.template.md](references/blueprint.template.md)):
   - **Escopo**: quais domains pertencem a este app (derivado dos módulos; paths ajudam — `/admin/*`→adm, `/franchise/*`→franqueado, `/stores/{storeId}/*`→fornecedor, busca/carrinho/checkout→cliente). Domain ambíguo → listar como "em aberto" pro usuário decidir.
   - **Áreas → páginas**: agrupa por jornada, não por domain. Cada página lista os domains que consome.
   - **Navegação**: árvore da sidebar + rotas.
   - **Shell/layout**: proposta (ver regra de shell abaixo).
4. **Apresenta pro usuário revisar.** Só depois de aprovado, emite a fila (Fase 0c).

## Fase 1 — Drain colaborativo (self-driving opcional via `/loop`)

Para cada spec em `.spec/changes/UI-*` (menor `UI-<NNN>`):

1. Lê **só** essa spec (contém o contrato de UI da página: domains, colunas, campos, ações).
2. Constrói a página com `angular-engineer`: page *smart* (injeta `state`+`service`), componentes *dumb* em `shared/ui`, rota no app.
3. **Verifica**: `ng build <app>` + `ng test` verdes; a página renderiza (rode no browser / skill `run`).
4. Move `UI-<NNN>-<slug>/` pra `.spec/archive/` com `status: concluida`.
5. **Pausa pro usuário** (review/ajuste) antes da próxima — a menos que o usuário peça `/loop` pra drenar várias seguidas.

## Regras de mapeamento (módulo × domain → telas)

Um agente aplica de forma consistente:

### Persona → app
- Cada app é uma persona. O escopo de domains vem dos **módulos** daquele app; os paths dos services são desempate, não a regra.

### Jornada → área → página (NUNCA 1 página por domain)
- Agrupe RFs/fluxos dos módulos em **áreas** (ex.: Catálogo, Pedidos, Loja, Financeiro, Atendimento, Serviços).
- Cada área tem 1..N **páginas**. Uma página é um **vertical slice de um recurso**: tipicamente **lista → detalhe → criar/editar** do recurso principal, orquestrando os domains relacionados. **1 spec = 1 página.**
- Ex.: página "Produtos" = `produtos` + `variantes-de-produto` + `imagens-de-produto` + `horarios-de-produto`, lendo `categorias` — **não** quatro telas.

### Contrato de UI da página (inferido dos domains)
- **Colunas da tabela / campos do detalhe** ← interfaces `*Response` do `model.ts` (enums → tags/labels; datas → formatadas).
- **Campos do formulário + validação** ← interfaces `*Request` do `model.ts` (`required`→obrigatório, enum→select, `| null`→opcional).
- **Ações** ← métodos públicos do `service.ts`: `listar`→tabela; `buscarPorId`→detalhe; `criar`/`atualizar`→form; `excluir`→ação destrutiva (confirm); só `listar`→dashboard/relatório (sem CRUD); `obterMinha`→tela de perfil.
- **Estados de UI** ← signals do `state.ts`: `carregando`→skeleton/spinner; `erro` (ProblemDetails)→toast/inline; `itens`/`selecionado`→binding.

### Navegação
- Sidebar agrupada por área; rota por página (`/<area>/<recurso>`, detalhe `/<area>/<recurso>/:id`). Página inicial = dashboard/home da persona.

### Shell / layout
- **Shell padrão de painel**: sidebar colapsável (navegação) + topbar (contexto da persona — ex.: seletor de loja, notificações via domain de notifications, menu do usuário) + `router-outlet`. Layout de **login/auth separado** do shell.
- **Smart vs dumb**: páginas são smart; tabelas/forms/cards são dumb em `libs/shared/ui`.
- Use a **UI lib e o tema definidos no projeto** (ver README do front) — não invente outra.

## Spec por página

Cada página vira `.spec/changes/UI-<NNN>-<slug>/spec.md`, **auto-preenchida** a partir do blueprint (o usuário revisa, não responde questionário). Estende o template de spec do projeto com uma seção **"Contrato de UI"**. Ver [references/screen-spec.template.md](references/screen-spec.template.md). Campos-chave do frontmatter: `id: UI-<NNN>`, `tipo: ui-screen`, `app: <app>`, `area: <area>`, `dominios: [...]`, `status`.

> Por que `UI-<NNN>` e não `SPEC-<NNN>`: namespace próprio pra coexistir na fila com specs de backend/contract-sync sem colisão de numeração. A estrutura é a mesma do template SDD, então `spec-review`/`spec-tasks` continuam funcionando nelas.

## Pré-requisito: shell + design system (1×, idempotente)

Antes de drenar a primeira página, garanta o **shell** e a **UI lib**:
- Se não existir AppShell (sidebar/topbar/outlet) + auth layout + `authGuard`, **scaffolda 1×** com `angular-engineer` e a UI lib do projeto.
- Se a UI lib (ex.: a do README) não estiver no `package.json`/`styles`, instale e configure o tema antes.
- Rotas com **stubs vazios** por área dão um esqueleto clicável já no começo.

Isto é o análogo aos pré-requisitos que o `api-contract-sync` criava (`API_BASE_URL`, `ProblemDetails`) antes de drenar: infra compartilhada que toda página assume.

## Política de re-sync / drift

- **Blueprint** é regenerável; ao re-rodar, **não sobrescreva** páginas já construídas — reporte diffs (páginas novas/removidas/áreas mudadas) pro usuário.
- **Drift de domain** (quando `api-contract-sync` muda o contrato): uma página pode consumir um campo/método que sumiu. No MVP, apenas **reporte** (grep dos domains usados pela página). Detecção automática de drift de tela é evolução futura (v2).

## Como invocar

```
/ui-blueprint
```

### Fase 0 — Blueprint + fila

```bash
# 0a: índice factual dos domains (não passa por LLM)
node skills/ui-blueprint/scripts/index-domains.mjs \
  --domains-root frontend/libs/domains/src/lib \
  --out .spec/discovery/_domain-index.md
```

Depois o agente lê `.spec/discovery/module_*.md` + `_domain-index.md`, escreve `<app>-blueprint.md`, **você revisa**, e a skill emite a fila `.spec/changes/UI-*`.

### Fase 1 — Drain colaborativo

Construa uma página por vez (revisando entre elas). Para drenar várias seguidas sem acionar cada passo, envolva com `/loop` (self-paced): cada iteração constrói + arquiva uma página.

## Saída

- `.spec/discovery/_domain-index.md` — índice factual dos domains.
- `.spec/discovery/<app>-blueprint.md` — escopo, áreas → páginas, navegação, shell (artefato pra revisar).
- Fila `.spec/changes/UI-<NNN>-<slug>/spec.md` — uma por página.
- Por página drenada: page smart + dumb components + rota, buildada/testada, e a spec arquivada em `.spec/archive/`.
- Relatório de escopo (domains incluídos/ambíguos) e, em re-sync, diffs de blueprint e drift de domain.
