---
name: project-onboard
description: Faz engenharia reversa leve de um projeto JÁ EXISTENTE — detecta stack, mapeia a arquitetura rastreando o fluxo de UMA feature de referência e grava `.spec/memory/architecture.md` + `.spec/memory/conventions.md` pra que specs futuras sigam o que já existe. Use quando o usuário quer adotar o fluxo SDD num projeto que já tem código, mapear a arquitetura atual, ou preparar o terreno antes de refatorar/adicionar features. Triggers: "/project-onboard", "projeto existente", "mapear arquitetura", "onboarding do codebase".
---

# Project Onboard — Engenharia Reversa Leve

Par do [`/app-kickoff`](../app-kickoff/SKILL.md), mas para projetos **brownfield** (que já têm código). Em vez de descobrir do zero, esta skill **lê o código de forma cirúrgica** pra entender a arquitetura atual e grava o resultado em `.spec/memory/`, de modo que `/spec-new`, `/spec-plan` e `/spec-review` consigam **seguir os padrões que já existem** ao planejar refatorações ou novas features.

## Quando usar

- Comando explícito `/project-onboard`.
- Usuário quer usar SDD num projeto que **já existe** (não é do zero → senão é `/app-kickoff`).
- Pedido pra "mapear a arquitetura", "entender o codebase", "documentar como o projeto funciona".
- Antes de abrir a primeira SPEC de refatoração/feature num projeto legado.

## Princípio nº 1: NÃO varrer o projeto inteiro

Leitura cirúrgica, guiada por referências do usuário. **Nunca** faça grep/glob recursivo no repo todo nem leia diretórios grandes "pra ver o que tem". O custo é alto e o sinal é baixo.

A regra é: **o usuário aponta, você lê**. Você só lê por conta própria:
- Arquivos de manifesto na raiz (cheap e altíssimo sinal): `package.json`, `angular.json`, `nx.json`, `pom.xml`, `build.gradle`, `go.mod`, `requirements.txt`, `Dockerfile`, `docker-compose.yml`.
- Um `Glob`/`ls` raso (1 nível) pra entender a estrutura de pastas de topo.
- Os arquivos **específicos** da feature de referência que o usuário indicar.

Se precisar varrer mais do que isso, **pergunte** em vez de sair lendo.

## Processo

### Fase 0 — Delimitar o escopo (pergunte antes de ler)

Use `AskUserQuestion` (ou pergunta direta) pra coletar:

1. **Onde está o quê** — caminho do backend, do frontend, e se é monorepo/multi-repo.
2. **Uma feature de referência completa** — peça pro usuário apontar uma feature representativa e seus pontos de entrada, pra rastrear o fluxo ponta-a-ponta. Ex.:
   - Backend: `Controller` → `Service` → `Repository` → entidade/migration.
   - Frontend: rota/página → store/facade → service → client de API.
3. **O que ele quer fazer a seguir** — refatorar algo específico? adicionar feature nova? (ajuda a focar a análise no que importa).

> Se o usuário não souber apontar uma feature, sugira uma a partir dos manifestos/estrutura de topo e **confirme** antes de mergulhar.

### Fase 1 — Detectar stack e topologia

Leia **apenas os manifestos** e faça um `Glob`/`ls` raso de topo. Identifique:

- **Linguagens e frameworks** com **versões reais** (não suposições) — anote a fonte (qual arquivo/linha).
- **Topologia**: monolito, monorepo (Nx/Angular CLI/Gradle multi-módulo), múltiplos apps?
- **Banco / persistência**, build, gerenciador de pacotes, ferramentas de qualidade (lint, formatter, test runner).
- **Pontos de integração** óbvios (clientes HTTP, filas, provedores externos) declarados nas dependências.

### Fase 2 — Rastrear o fluxo da feature de referência

Usando **só** os arquivos que o usuário apontou (e os que eles importam diretamente), siga o caminho vertical completo de uma request/ação:

- Backend: request → camada web → aplicação/domínio → persistência → resposta. Onde mora a regra de negócio? Como erros são tratados? Onde fica a transação?
- Frontend: ação do usuário → componente → estado (signal/store/facade) → service → client de API → render.

Documente o **caminho** (com diagrama Mermaid quando ajudar) e o **padrão arquitetural** que ele revela (camadas, DDD, hexagonal, MVC, etc.).

> Para manter o contexto principal limpo, considere delegar o rastreamento a um subagente **Explore** com escopo restrito (apenas os arquivos da feature). Peça de volta só a conclusão: camadas percorridas + como se conectam.

### Fase 3 — Extrair convenções

A partir da feature rastreada (e de 1-2 arquivos irmãos pra confirmar que é padrão, não exceção), registre o que é **convenção repetida**, não detalhe isolado:

- Nomenclatura (arquivos, classes, pastas, endpoints).
- Estrutura de pastas por camada / por módulo.
- Padrões de teste (onde ficam, que tipo, naming).
- Tratamento de erros e contrato de API.
- Fluxo de estado no frontend.
- Anti-padrões/dívidas observados — separe "convenção a seguir" de "dívida a não replicar".

### Fase 4 — Gravar a memória do projeto

Crie (ou atualize) em `.spec/memory/`:

- **`architecture.md`** — a partir de [references/architecture.template.md](references/architecture.template.md).
- **`conventions.md`** — a partir de [references/conventions.template.md](references/conventions.template.md).

Confirme com o usuário antes de gravar; sinalize explicitamente tudo que for **inferência** (vs. confirmado no código) pra ele validar.

## Como invocar

```
/project-onboard
/project-onboard "backend em ./api (Spring), front em ./web (Angular). Feature de referência: cadastro de clientes"
```

## Saída final

- `.spec/memory/architecture.md` e `.spec/memory/conventions.md` preenchidos e validados.
- Resumo de 5-10 linhas: stack detectado, padrão arquitetural, "caminho" pra adicionar uma feature nova.
- Lista de **inferências a confirmar** e **dívidas/tensões** encontradas.
- Próxima ação: `/spec-new` — a partir daqui o fluxo SDD segue normal, e `/spec-plan`/`/spec-review` vão consultar esta memória pra manter a coerência com o que já existe.

## Como NÃO usar

- ❌ Não use em projeto vazio/novo — isso é `/app-kickoff`.
- ❌ Não faça grep/glob recursivo no repo todo nem leia src inteiro.
- ❌ Não invente versões/frameworks — toda tecnologia citada sai de um manifesto ou de um arquivo lido.
- ❌ Não documente uma exceção como se fosse padrão — confirme em ≥2 lugares antes de chamar de "convenção".
- ❌ Não replicar dívida técnica como recomendação — separe o que é padrão saudável do que é legado a evitar.

## Sinais de alerta (red flags)

- **Tentação de varrer** — se você quer "só dar uma olhada geral", pare e peça uma referência.
- **Inconsistência interna** — duas features seguem padrões diferentes: registre as duas e pergunte qual é a oficial.
- **Stack divergente do declarado** — manifesto diz X, código usa Y: anote e confirme.
- **Feature de referência atípica** — se o usuário apontou um caso especial, peça uma mais representativa.
