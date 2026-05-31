---
name: app-kickoff
description: Conduz a descoberta inicial de um novo aplicativo gerando artefatos em `.spec/discovery/` (brief, um module_<nome>.md por módulo, entities, roadmap). Use quando o usuário invoca `/app-kickoff`, está iniciando um produto novo, ou quer mapear funcionalidades, modelar entidades e definir roadmap de entrega. Triggers: "/app-kickoff", "novo projeto", "vamos fazer o kickoff", "descoberta de produto".
---

# App Kickoff — Descoberta Modular

Skill para conduzir o **kickoff de descoberta** de um novo aplicativo. Produz artefatos sequenciais em `.spec/discovery/` que servem de base para abrir SPECs via `/spec-new`:

- `brief.md` — visão de produto, atores, arquitetura macro, fases, lista de módulos
- `module_<nome>.md` — **um arquivo por módulo** (ex: `module_auth.md`, `module_clientes.md`)
- `entities.md` — modelagem conceitual + técnica
- `roadmap.md` — ordem de execução com fases e SPECs sugeridas

## Quando usar

- Comando explícito `/app-kickoff` (com ou sem frase descritiva).
- Usuário descreve um sistema novo e lista módulos funcionais.
- Pedido para "iniciar projeto", "fazer descoberta", "documentar requisitos do zero".
- Necessidade de chegar até roadmap de entregas (não apenas requisitos).

## Princípios fundamentais

1. **Um módulo por vez.** Nunca cobre múltiplos módulos numa mesma rodada de perguntas.
2. **Pergunte antes de escrever.** Use `AskUserQuestion` para validar pontos críticos *antes* de redigir.
3. **Confirme decisões estruturais cedo.** Quando o usuário esclarece algo que afeta múltiplos módulos (multi-tenant, fases, canais, escopo), salve em memória imediatamente.
4. **Marque fases explicitamente.** Em cada requisito, deixe claro o que é Fase 0/1/2/Futura.
5. **Sinalize tensões.** Quando dois requisitos parecem conflitar, pare e clarifique antes de seguir.
6. **Não invente.** Pergunte ao usuário. Inferir errado custa retrabalho em todos os artefatos seguintes.
7. **Confirme entre fases.** Não passe de uma fase para a próxima sem o "ok" do usuário.

## Processo

### Fase 1 — Brief inicial

**Objetivo**: preencher `.spec/discovery/brief.md` com contexto fundamental antes de detalhar módulos.

**O que coletar**:

1. **Visão de produto** em 2-3 frases.
2. **Atores e perfis** (admin, usuário final, integrações externas, etc.).
3. **Arquitetura macro** (multi-tenant? quem cadastra quem? stack pretendido?).
4. **Fases de entrega** (MVP, Fase 2 se houver, Futuro — explicitar o que cabe em cada).
5. **Lista de módulos funcionais** que serão detalhados na Fase 2.
6. **Restrições conhecidas** (compliance, performance, integrações obrigatórias).

**Roteiro**:

1. Se o usuário invocou `/app-kickoff "frase descritiva"`, parta da frase. Caso contrário, peça descrição em 1 mensagem.
2. Use `AskUserQuestion` para confirmar atores, multi-tenant e fases — decisões que afetam todos os módulos seguintes.
3. Salve decisões estruturais em memória (`project_overview`, `project_phases`, `project_stack`).
4. Crie `TodoWrite` com uma tarefa por módulo identificado + tarefas para Entities e Roadmap.

**Saída**: `.spec/discovery/brief.md` consolidado + atualização sugerida de [memory/glossary.md](../../../../.spec/memory/glossary.md) com termos novos. Confirmar antes da Fase 2.

### Fase 2 — Detalhamento por módulo

**Objetivo**: criar **um arquivo por módulo** em `.spec/discovery/module_<nome>.md` (ex: `module_auth.md`, `module_clientes.md`, `module_dashboard.md`).
Cada módulo num arquivo próprio evita que o documento fique extenso demais e facilita navegação/PR review.

**Roteiro por módulo** (executar sequencialmente):

1. **Abrir o módulo.** Diga "vamos ao Módulo X" e faça 3-4 perguntas em `AskUserQuestion`:
   - Use `multiSelect: true` quando faz sentido escolher múltiplas opções.
   - Cada opção: `label` curto + `description` explicando trade-off.
   - Recomendações vão primeiro com "(Recomendado)" no label.
   - Cubra: escopo principal, fluxos críticos, dados sensíveis, integrações.
2. **Refine.** Faça uma segunda rodada para pontos operacionais (validade, expiração, granularidade, anti-vazamento, falhas, triggers).
3. **Sinalize contradições.** Se uma escolha conflita com algo já decidido em módulo anterior, mostre o conflito e proponha resoluções.
4. **Crie o arquivo** `.spec/discovery/module_<nome>.md` usando a estrutura padrão (template abaixo).
5. **Marque a tarefa como completa** no TodoWrite e anuncie em 1-2 frases o que foi documentado, com link clicável pro arquivo (`[module_<nome>.md](.spec/discovery/module_<nome>.md)`).
6. **Espere "ok"** do usuário antes de seguir para o próximo módulo.

**Estrutura padrão de cada arquivo `module_<nome>.md`**:

```markdown
# Módulo — Nome

## Visão Geral
[propósito do módulo, valor que entrega, fases aplicáveis]

## Atores
[perfis e interações]

## Conceitos-Chave
[termos novos — anotar para sugerir no glossário]

## Requisitos Funcionais
- **RF-01**: ...
- **RF-02**: ...

## Requisitos Não Funcionais
- **RNF-01 (Categoria)**: ...

## Regras de Negócio
- **RN-01**: ...

## Fluxos Principais
### Fluxo 1 — Nome
1. Passo
2. Passo

## Integrações
- ...

## Pontos em Aberto
- ...
```

> Numeração de RFs/RNFs/RNs é **local ao arquivo** (`RF-01`, `RF-02`, ...). Para referência cruzada entre módulos, prefixe com o nome do arquivo: `module_auth.md#rf-03`.

**Saída**: um arquivo `.spec/discovery/module_<nome>.md` por módulo + termos novos sugeridos pro glossário.

### Fase 3 — Modelagem de entidades

**Objetivo**: preencher `.spec/discovery/entities.md` a partir dos requisitos nos arquivos `module_<nome>.md`.

**Roteiro**:

1. **Decisões Transversais primeiro.** Antes de modelar entidades, conduzir as decisões da seção 1 do [entities.template.md](../../../../.spec/templates/entities.template.md) via `AskUserQuestion` (em batch ou em rodadas curtas):
   - **1.1 Identificadores** — UUID gerado pela app / UUID pelo BD / BIGSERIAL / outro
   - **1.2 Tenancy** — single-tenant / multi-tenant com RLS / schema-per-tenant / database-per-tenant
   - **1.3 Auditoria** — sem / timestamps básicos / quem+quando / log em tabela separada
   - **1.4 Soft delete** — hard em todas / soft em todas / case-a-case
   - **1.5 Versionamento** — sem / histórico em tabela / coluna versao (locking) / event sourcing
   - **1.6 Enums vs catálogos** — enums no código / tabelas gerenciáveis / combinação

   Registrar cada decisão na seção 1 do `entities.md` com justificativa curta. **Nada é assumido por default** — perguntar mesmo o "óbvio".

2. **Listar entidades por domínio.** Identificadas nos arquivos `module_<nome>.md` (substantivos: cliente, processo, documento, fatura, etc.). Domínios geralmente alinham com módulos, mas alguns agregam vários.

3. **Pra cada entidade, uma `AskUserQuestion`** com 3-5 perguntas em batch:
   - Atributos principais (sem tipo SQL ainda)
   - Relacionamentos (1:N, N:N)
   - Invariantes (regras que sempre valem)
   - Eventos de domínio (se aplicável)
   - Value Object ou Entity?

4. **Marcar raiz de agregado** (`AR`) quando aplicável.

5. **Registrar observações específicas** por entidade apenas quando ela **diverge** das decisões transversais (ex: "auditoria: log completo — requisito LGPD do módulo X").

6. **Gerar ERD consolidado em Mermaid.**

**Heurísticas**:

- **Nada é default.** Auditoria, soft delete, multi-tenant, versionamento — tudo são decisões deste projeto, conduzidas na seção 1.
- Atributo "data" ou "info" sem qualificador é cheiro — sempre nome específico.
- Se uma entidade tem só id + atributos sem comportamento, considerar Value Object.

**Saída**: `.spec/discovery/entities.md` com decisões transversais + tabelas por domínio + ERD + termos novos. Confirmar a Etapa 1 (Conceitual) antes de partir pra Etapa 2 (Técnica).

### Fase 4 — Roadmap

**Objetivo**: preencher `.spec/discovery/roadmap.md`.

**Critérios na ordem**:

1. **Desbloqueio**: o que destrava outros vai antes (auth quase sempre).
2. **Risco técnico**: atacar dúvida grande cedo.
3. **Valor entregue**: caminho mais curto até "usuário ver algo".
4. **Reversibilidade**: schema/contrato grandes cedo; refatoráveis depois.

**Sempre incluir Fase 0 — Fundação técnica** (setup, CI, banco, observabilidade, error handling, OpenAPI/cliente TS).

**Pra cada fase do roadmap**:

- Justificar por que essa fase agora (1-2 frases).
- Listar 2-4 specs sugeridas (depois viram SPEC-NNN via `/spec-new`).
- Critério de pronto da fase.

**Saída**: `.spec/discovery/roadmap.md` + sugestão concreta de qual SPEC abrir primeiro.

## Como invocar

```
/app-kickoff
/app-kickoff "Plataforma de gestão de X com áreas: Auth, Gestão de Y, Dashboard, IA, Notificações"
```

## Saída final do skill

Arquivos em `.spec/discovery/`:
- `brief.md`
- `module_<nome>.md` — um por módulo (`module_auth.md`, `module_clientes.md`, ...)
- `entities.md`
- `roadmap.md`

Mais:
- Resumo executivo de 5-10 linhas pro usuário.
- Sugestão: atualizar [memory/glossary.md](../../../../.spec/memory/glossary.md) com termos novos.
- Próxima ação: `/spec-new` pra abrir a primeira SPEC do roadmap.

## Padrões de perguntas que funcionam bem

Cada `AskUserQuestion` deve ter:
- **Pergunta direta** com contexto suficiente para resposta informada.
- **2-4 opções**, cada uma com `label` curto + `description` explicando trade-off.
- **`multiSelect`** quando a escolha não for mutuamente exclusiva.

Tipos de pergunta produtivos:
- **Escopo**: "Quais funcionalidades devem existir no módulo X?"
- **Cardinalidade**: "Uma entidade A pode ter quantas entidades B?"
- **Workflow**: "Quais status/fases o item passa?"
- **Tratamento de falha**: "O que acontece quando X falha?"
- **Validade/expiração**: "Quanto tempo dura o acesso/token/permissão?"
- **Granularidade**: "Permissões fixas por perfil, ou customizáveis por usuário?"
- **Trigger/disparo**: "Quando o pipeline/notificação dispara?"
- **Conflito**: "Sobre a tensão entre A e B, como resolver?"
- **DDD**: "Essa entidade tem comportamento próprio (Entity) ou só representa um valor imutável (Value Object)?"

## Memória entre conversas

Use o sistema de memória para guardar:
- **project**: visão geral, fases, stack técnico, decisões estruturais (multi-tenant, atores, módulos removidos do escopo)
- **feedback**: padrões que o usuário corrigiu (não modelar X, preferir Y); decisões metodológicas
- **reference**: links para sistemas externos mencionados

Padronize nomes: `project_overview.md`, `project_phases.md`, `project_stack.md`, `feedback_xxx.md`.

Glossário do projeto vive em `.spec/memory/glossary.md` — atualize com termos novos descobertos em cada fase.

## Sinais de alerta (red flags)

Pare e clarifique quando perceber:
- **Contradição entre módulos** (ex.: módulo 1 fala em e-mail+SMS, módulo 8 inclui WhatsApp).
- **Termo técnico ambíguo** (ex.: "E2EE com logs de conteúdo" — é incompatível com E2EE estrito).
- **Escopo crescendo sem limite** (cada pergunta adiciona requisitos novos sem critério de corte).
- **Sobreposição entre módulos** (vale perguntar se é redundância).
- **Decisão tomada sem confirmação** que afeta múltiplos módulos.
- **Entidade "Genérica"** sem comportamento — considerar Value Object ou agregar em outra entity.

## Boas práticas operacionais

- **Atualize TodoWrite imediatamente** ao concluir cada módulo/fase. Não acumule.
- **Link clicável** para os arquivos gerados ao final de cada fase (`[brief.md](.spec/discovery/brief.md)`).
- **Renumere referências cruzadas** quando o usuário fizer mudanças retroativas (ex.: removeu um canal, ajuste em todos os módulos).
- **Diga em 1-2 frases o que foi feito + próximo passo** ao final de cada fase.
- **Não invente nomes técnicos** (bibliotecas, serviços) — pergunte ou liste opções.
- **Pontos em aberto** ficam no final de cada módulo. Não force decisão prematura.
- **Termine cada fase com um convite explícito**: "Quando estiver pronto, partimos para a Fase X — vou explorar A, B e C."

## Anti-padrões a evitar

- ❌ Listar requisitos sem perguntar antes (gera retrabalho).
- ❌ Criar arquivos separados por módulo (use `modules.md` consolidado — uma seção por módulo).
- ❌ Usar `AskUserQuestion` com mais de 4 opções por pergunta (sobrecarga).
- ❌ Pular a etapa conceitual de entidades e ir direto para SQL/DDL.
- ❌ Repetir entidade já removida pelo usuário (consulte memória).
- ❌ Adicionar features que o usuário não pediu ("seria legal ter X também...").
- ❌ Pular Fase 0 (Fundação técnica) no roadmap — ela é obrigatória.
- ❌ Trazer suposições do prompt anterior para um módulo onde o usuário pode ter mudado de ideia — re-confirme em pontos críticos.
- ❌ Esquecer auditoria implícita e repetir `criadoEm/atualizadoEm` em cada entidade do `entities.md`.
