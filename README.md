# SDD Template — Angular 18+ / Java Spring

Repositório template de **Spec-Driven Development** com pastas `.spec/` e skills do Claude Code prontas pra serem **copiadas em qualquer projeto novo**.

Inspirado no [GitHub Spec Kit](https://github.com/github/spec-kit), adaptado pra stack Angular 18+ no frontend e Java/Spring no backend.

## O que está aqui

```
.
├── .spec/                  # Templates e memória do fluxo SDD (copiar para projeto destino)
│   ├── memory/             # Constitution, stack, conventions, glossary (HOW we work)
│   ├── templates/          # brief, modules, entities, roadmap, spec, plan, tasks, adr, ...
│   ├── discovery/          # Vazio — recebe brief/modules/entities/roadmap do kickoff
│   ├── archive/            # Vazio — recebe specs concluídas no projeto destino
│   ├── changes/            # Vazio — recebe specs em andamento no projeto destino
│   └── shared/             # Personas, NFRs, error-handling, observability, angular-monorepo
└── .claude/
    └── skills/             # Skills do Claude Code (copiar para projeto destino)
        ├── sdd/            # app-kickoff + spec-new, spec-plan, spec-tasks, spec-review
        ├── angular/        # ng-component, ng-feature, ng-test
        ├── spring/         # spring-crud, spring-test, spring-migration
        └── extras/         # adr-new, api-contract-sync, code-review-stack
```

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

### 2. Copiar as skills do Claude Code

```bash
cp -R .claude /caminho/do/seu/projeto/
```

Se o projeto já tiver `.claude/`, copie apenas o conteúdo de `skills/`:

```bash
mkdir -p /caminho/do/seu/projeto/.claude/skills
cp -R .claude/skills/* /caminho/do/seu/projeto/.claude/skills/
```

### 3. Customizar pelo projeto destino

Edite os arquivos da pasta `.spec/memory/`:

- **`constitution.md`** — ajuste princípios pro contexto do projeto.
- **`tech-stack.md`** — preencha versões reais que o projeto está usando.
- **`conventions.md`** — adapte convenções específicas (estrutura de pastas, padrões de nomes).
- **`glossary.md`** — substitua os termos de exemplo pelos termos do **domínio do projeto**.

`.spec/shared/personas.md` e `.spec/shared/nfr-catalog.md` são bons defaults — só edite quando algo do projeto diverge.

### 4. Começar o fluxo

**Projeto novo (do zero)** — kickoff guiado em 4 fases:

```
/app-kickoff               # brief → módulos → entidades → roadmap
```

Você descreve o sistema e lista as áreas/módulos. O skill conduz perguntas específicas via `AskUserQuestion` (3-5 por batch), preenche 4 artefatos em `.spec/discovery/` e ao final aponta a primeira SPEC a abrir.

**Depois do kickoff** (ou para projetos já em andamento):

```
/spec-new                  # cria uma spec nova guiada
/spec-plan SPEC-001        # gera plano técnico
/spec-tasks SPEC-001       # quebra em tarefas
/spec-review SPEC-001      # revisa antes de aprovar
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
0. app-kickoff   → .spec/discovery/brief.md
                 + .spec/discovery/module_<nome>.md   (um por módulo)
                 + .spec/discovery/entities.md
                 + .spec/discovery/roadmap.md
                 + decisões estruturais salvas em memory do projeto
       ↓
1. spec-new      → .spec/changes/SPEC-NNN-slug/spec.md
2. spec-review   → validar antes de planejar
3. spec-plan     → plan.md ao lado da spec
4. spec-tasks    → tasks.md com lista executável
5. <implementar usando skills de stack: ng-*, spring-*>
6. code-review-stack  → revisar diff antes do PR
7. <feature mergeada>
8. mover pasta SPEC-NNN-slug/ para .spec/archive/
```

## Skills disponíveis

### SDD (fluxo)

| Skill | Função |
|-------|--------|
| `app-kickoff` | Kickoff em 4 fases: brief → módulos (RFs/RNFs/regras/fluxos) → entidades (conceitual + técnica) → roadmap |
| `spec-new` | Cria spec nova, guiada por perguntas |
| `spec-plan` | Gera plano técnico a partir da spec |
| `spec-tasks` | Quebra plano em tarefas executáveis |
| `spec-review` | Revisa spec/plano antes de aprovar |

### Angular 18+

| Skill | Função |
|-------|--------|
| `ng-component` | Componente standalone + signals + OnPush + teste |
| `ng-feature` | Scaffold de feature completa (rotas + páginas + store) |
| `ng-test` | Testes com Jest ou Karma seguindo padrões |

### Java / Spring

| Skill | Função |
|-------|--------|
| `spring-crud` | Entity + Repository + Service + Controller + Mapper + migration |
| `spring-test` | Slice tests (`@WebMvcTest`, `@DataJpaTest`) + integração com Testcontainers |
| `spring-migration` | Migration Flyway forward-only com nomenclatura padronizada |

### Extras

| Skill | Função |
|-------|--------|
| `adr-new` | Registra Architecture Decision Record |
| `api-contract-sync` | Sincroniza OpenAPI ↔ client TS Angular |
| `code-review-stack` | Code review do diff aplicando checklist da stack |

## Atualizando o template

Quando você descobrir algo que vale pra todos os projetos:

1. **Volte aqui**, edite o template/skill correspondente.
2. **Não** propague pra cada projeto manualmente — espere o próximo bootstrap, ou faça um `diff` cirúrgico quando precisar.
3. Se a mudança é grande e quebra projetos existentes, registre num ADR aqui mesmo (`.spec/archive/adr/`).

## Convenções deste template

- **Idioma**: conteúdo de templates e skills em PT-BR; identificadores e palavras-chave em inglês.
- **Stack-alvo**: Angular 18+ (signals, standalone, OnPush) e Spring Boot 3.3+ (Java 21).
- **Distribuição**: copy/paste manual (não é submodule nem pacote npm).
