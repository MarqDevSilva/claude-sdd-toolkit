---
name: spec-init
description: Cria a estrutura .spec/ completa (discovery, changes, archive, memory, templates) num projeto que ainda não a tem, deixando o terreno pronto pro fluxo SDD. Use quando o usuário abre um projeto sem .spec/, pede pra "inicializar o SDD aqui", "criar a pasta .spec", "preparar o projeto pro fluxo de specs" ou bootstrap inicial. Triggers: "/spec-init", "não tem .spec", "inicializar SDD", "criar estrutura de specs".
---

# spec-init

Use esta skill quando o projeto **ainda não tem a pasta `.spec/`** e o usuário quer
deixar o terreno pronto pro fluxo SDD — ou quando ele pede explicitamente pra
**inicializar o SDD**, **criar a estrutura de specs** ou **fazer o bootstrap** do diretório.

É o passo zero do fluxo: não cria specs nem faz descoberta, só **scaffolda as pastas**.
Depois dela o usuário roda `/app-kickoff` (projeto novo) ou `/project-onboard` (existente).

## O que faz

1. Verifica se já existe `.spec/` na raiz do projeto.
   - **Não existe** → cria a estrutura completa.
   - **Já existe** → completa só o que estiver faltando (idempotente, nunca apaga nada).
2. Roda o script [scripts/init-spec.sh](scripts/init-spec.sh), que cria:

   ```
   .spec/
   ├── discovery/    # saída do /app-kickoff: brief, module_<nome>, entities, roadmap
   ├── changes/      # specs em andamento: SPEC-NNN-slug/ (spec.md → plan.md → tasks.md)
   ├── archive/      # specs concluídas
   ├── memory/       # /project-onboard: architecture.md + conventions.md
   └── templates/    # templates próprios do projeto (opcional)
   ```

   Cada subpasta recebe um `.gitkeep` (pra versionar a pasta vazia) e a raiz recebe um
   `README.md` explicando o papel de cada uma.
3. Resume pro usuário o que foi criado/pulado e aponta o próximo passo.

## Como invocar

```
/spec-init                  # cria .spec/ no diretório atual
/spec-init /caminho/projeto # cria em outra raiz
```

Por baixo, a skill executa:

```bash
bash skills/spec-init/scripts/init-spec.sh [destino] [--dry-run] [--force] [--no-readme]
```

> Se a skill estiver instalada em `.claude/skills/`, o caminho do script é
> `.claude/skills/spec-init/scripts/init-spec.sh`.

## Opções do script

- `--dry-run` — mostra o que seria criado, sem escrever nada. **Use primeiro** quando
  estiver em dúvida sobre o estado atual do projeto.
- `--force` — reescreve `.spec/README.md` se já existir (pastas e `.gitkeep` nunca são tocados).
- `--no-readme` — cria só as pastas + `.gitkeep`, sem o README.

## Comportamento esperado

- **Idempotente e seguro.** Pasta ou arquivo que já existe é preservado (skip), nunca
  sobrescrito — exceto o README quando `--force` é passado. Pode rodar quantas vezes quiser.
- **Rode na raiz do projeto** (onde fica o `.git`, `package.json`, `pom.xml`, etc.).
  Se houver dúvida sobre qual é a raiz, confirme com o usuário antes.
- Se `.spec/` **já existe e está completo**, diga isso e não invente trabalho — sugira
  direto o `/app-kickoff` ou `/project-onboard`.
- Depois de criar, **não** comece o kickoff por conta própria: aponte o próximo passo e
  deixe o usuário decidir.

## Como NÃO usar

- Não use pra criar uma spec — isso é `/spec-new`.
- Não use pra fazer descoberta de produto ou mapear arquitetura — isso é
  `/app-kickoff` e `/project-onboard`.
- Não apague nem reescreva conteúdo existente em `.spec/` "pra começar limpo" sem o
  usuário pedir explicitamente; a skill é aditiva por design.

## Saída final

- Estrutura `.spec/` criada (ou completada) na raiz do projeto.
- Resumo curto: o que foi criado vs. pulado e o próximo passo sugerido
  (`/app-kickoff` para projeto novo, `/project-onboard` para projeto existente).
