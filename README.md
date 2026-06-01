# SDD Template — Angular 18+ / Java Spring

Repositório template de **Spec-Driven Development** com a pasta `.spec/` e as skills do Claude Code prontas pra serem **copiadas em qualquer projeto novo**.

Inspirado no [GitHub Spec Kit](https://github.com/github/spec-kit), adaptado pra stack Angular 18+ no frontend e Java/Spring no backend.

## O que está aqui

```
.
├── .spec/                  # Diretório de trabalho do fluxo SDD (copiar para projeto destino)
│   ├── discovery/          # Vazio — recebe brief/module_*/entities/roadmap do kickoff
│   ├── changes/            # Vazio — recebe specs em andamento (SPEC-NNN-slug/)
│   ├── archive/            # Vazio — recebe specs concluídas
│   ├── memory/             # (gerado por project-onboard) architecture.md + conventions.md
│   └── templates/          # Vazio — espaço pra templates próprios do projeto, se quiser
├── skills/                 # Skills do Claude Code (cada uma autocontida)
│   ├── app-kickoff/        # SKILL.md + references/ (brief, modules, entities, roadmap) — projeto NOVO
│   ├── project-onboard/    # SKILL.md + references/ (architecture, conventions) — projeto EXISTENTE
│   ├── spec-new/           # SKILL.md + references/spec.template.md
│   ├── spec-plan/          # SKILL.md + references/ (plan, api-contract)
│   ├── spec-tasks/         # SKILL.md + references/tasks.template.md
│   ├── spec-review/        # SKILL.md + references/review-checklist.md
│   ├── angular-engineer/   # SKILL.md + references/ (components, state, api-client, testing, lint)
│   ├── spring-boot-engineer/ # SKILL.md + references/ (web, data, security, error-handling, ...)
│   └── api-contract-sync/  # SKILL.md
├── install-skill.sh        # Importa uma skill de outro repo público (via npx degit)
└── README.md
```

> Cada skill é **autocontida**: os templates que ela usa vivem em `<skill>/references/`, não num diretório central. Copiar a pasta da skill leva tudo junto.

> O **kickoff** do projeto destino preenche em `.spec/discovery/`:
> - `brief.md` — visão de produto, atores, arquitetura macro, fases, lista de módulos
> - `module_<nome>.md` — **um arquivo por módulo** (ex: `module_auth.md`, `module_clientes.md`) com RFs, RNFs, regras, fluxos, integrações
> - `entities.md` — modelagem conceitual + técnica (DDL/RLS PostgreSQL)
> - `roadmap.md` — ordem de execução com fase 0 (fundação) + fases por módulo + SPECs sugeridas

## Como usar em um projeto novo

### 1. Copiar a pasta `.spec/`

Da raiz deste repo para a raiz do projeto destino:

```bash
cp -R .spec /caminho/do/seu/projeto/
```

### 2. Copiar as skills para `.claude/skills/`

O Claude Code procura skills em `.claude/skills/`. Copie as pastas que quiser:

```bash
mkdir -p /caminho/do/seu/projeto/.claude/skills
cp -R skills/* /caminho/do/seu/projeto/.claude/skills/
```

Cada pasta de skill já carrega seu próprio `references/` — não há diretório de templates separado pra copiar.

### 3. Estabelecer o contexto do projeto

As skills SDD são autocontidas, mas ficam **muito melhores** quando existe uma memória do projeto em `.spec/memory/`. Como você a obtém depende de o projeto ser novo ou já existir:

- **Projeto existente (brownfield)** → rode `/project-onboard`. Ele faz engenharia reversa **leve** (sem varrer o repo todo — você aponta os manifestos e uma feature de referência), detecta o stack, mapeia a arquitetura e grava `.spec/memory/architecture.md` + `.spec/memory/conventions.md`.
- **Projeto novo** → o `/app-kickoff` cobre a descoberta; a memória de arquitetura vai se formando conforme as primeiras features são construídas.

Sempre que `.spec/memory/` existir, `/spec-new`, `/spec-plan` e `/spec-review` o consultam pra manter novas features **coerentes com o que já existe**.

### 4. Começar o fluxo

**Projeto novo (do zero)** — kickoff guiado em 4 fases:

```
/app-kickoff               # brief → módulos → entidades → roadmap
```

Você descreve o sistema e lista as áreas/módulos. O skill conduz perguntas específicas via `AskUserQuestion` (3-5 por batch), preenche 4 artefatos em `.spec/discovery/` e ao final aponta a primeira SPEC a abrir.

**Projeto existente** — mapeie a arquitetura antes de mexer:

```
/project-onboard           # detecta stack → rastreia 1 feature → grava .spec/memory/
```

**Depois do kickoff / onboarding** (ou para projetos já em andamento):

```
/spec-new                  # cria uma spec nova guiada
/spec-review SPEC-001      # revisa antes de planejar
/spec-plan SPEC-001        # gera plano técnico
/spec-tasks SPEC-001       # quebra em tarefas executáveis
```

## Instalar skills de outros repos públicos

Quer importar uma skill de outro projeto público (ex.: um repo de skills da comunidade) **sem clonar o projeto inteiro**? Use o [`install-skill.sh`](install-skill.sh) — ele baixa **só aquela pasta** (via `npx degit`) direto pra `.claude/skills/`.

```bash
# Cole a URL da pasta no GitHub (formato /tree/branch/...)
./install-skill.sh https://github.com/Jeffallan/claude-skills/tree/main/skills/spring-boot-engineer
```

**Opções:**

```bash
./install-skill.sh <url> caminho/destino     # instala em outra pasta (padrão: .claude/skills)
./install-skill.sh <url> --force             # sobrescreve se já existir
./install-skill.sh owner/repo/path/skill#main  # atalho estilo degit
./install-skill.sh --help                    # ajuda
```

O script faz parse da URL, baixa apenas a subpasta, valida se tem `SKILL.md` e lista o conteúdo instalado.

> **Requisito:** Node.js (`npx`). É a única dependência extra.

## Fluxo SDD resumido

```
0a. app-kickoff      → (projeto NOVO) .spec/discovery/brief.md
                     + module_<nome>.md (um por módulo) + entities.md + roadmap.md
0b. project-onboard  → (projeto EXISTENTE) .spec/memory/architecture.md + conventions.md
       ↓
1. spec-new      → .spec/changes/SPEC-NNN-slug/spec.md   (consulta .spec/memory/ se existir)
2. spec-review   → validar antes de planejar
3. spec-plan     → plan.md ao lado da spec
4. spec-tasks    → tasks.md com lista executável
5. <implementar com as skills de stack: angular-engineer, spring-boot-engineer>
6. <sincronizar contrato com api-contract-sync, revisar diff, abrir PR>
7. <feature mergeada>
8. mover pasta SPEC-NNN-slug/ para .spec/archive/
```

## Skills disponíveis

### SDD (fluxo)

| Skill | Função |
|-------|--------|
| `app-kickoff` | **Projeto novo** — kickoff em 4 fases: brief → módulos (RFs/RNFs/regras/fluxos) → entidades (conceitual + técnica) → roadmap |
| `project-onboard` | **Projeto existente** — engenharia reversa leve: detecta stack, mapeia arquitetura e grava `.spec/memory/` |
| `spec-new` | Cria spec nova, guiada por perguntas |
| `spec-review` | Revisa spec/plano antes de aprovar |
| `spec-plan` | Gera plano técnico a partir da spec |
| `spec-tasks` | Quebra plano em tarefas executáveis |

### Stack

| Skill | Função |
|-------|--------|
| `angular-engineer` | Apps Angular 18+ em monorepo: domínios, signal state + facades, client OpenAPI gerado, ESLint/Prettier + testes |
| `spring-boot-engineer` | Apps Spring Boot 3.x monolito por bounded context: REST em camadas, Spring Security 6, Spring Data JPA, error handling, observabilidade |
| `api-contract-sync` | Sincroniza o contrato API entre Spring (springdoc OpenAPI) e Angular (client TS), detectando divergências back ↔ front |

### Mobile / KMP

| Skill | Função |
|-------|--------|
| `kmp-architect` | **Hub + roteador** de um projeto Kotlin Multiplatform (KMP + Koin + Ktor + SQLDelight + StateFlow / Compose / SwiftUI). Define arquitetura (MVVM + Clean por feature em `:shared`), nomes, pastas, erros, DI e testes — e roteia cada tarefa para a skill de expert certa |
| _experts KMP/Android/iOS_ | `kotlin-multiplatform`, `kotlin-expert`, `kotlin-coroutines`, `gradle-expert`, `compose-expert`, `android-expert`, `swiftui-patterns`, `swiftui-navigation`, `swiftui-layout-components`, `swiftui-animation`, `swiftui-gestures`, `swiftui-liquid-glass` — invocados **através** do `kmp-architect` |

> O `kmp-architect` é o ponto de entrada: consulte-o antes de gerar código KMP/Compose/SwiftUI. Ele aplica as convenções do projeto e delega os detalhes idiomáticos para os experts (que foram escritos para o projeto _Amethyst_ — o `kmp-architect` documenta o override da stack canônica).

## Atualizando o template

Quando você descobrir algo que vale pra todos os projetos:

1. **Volte aqui**, edite a skill ou o template (`<skill>/references/`) correspondente.
2. **Não** propague pra cada projeto manualmente — espere o próximo bootstrap, ou faça um `diff` cirúrgico quando precisar.

## Convenções deste template

- **Idioma**: conteúdo das skills e templates em PT-BR; identificadores e palavras-chave em inglês.
- **Stack-alvo**: Angular 18+ (signals, standalone, OnPush) e Spring Boot 3.x (Java 21).
- **Skills autocontidas**: cada skill carrega seus próprios templates em `references/`.
- **Distribuição**: copy/paste manual (não é submodule nem pacote npm).
```
