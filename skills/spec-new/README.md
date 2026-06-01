# spec-new

> Cria uma nova spec em `.spec/changes/` a partir do template, com preenchimento guiado.

Skill para abrir uma feature ou registrar uma mudança nova. Detecta o próximo `SPEC-<NNN>`, cria a pasta e o `spec.md`, e guia o usuário seção por seção (problema, objetivo, escopo, cenários, critérios de aceitação, NFRs, riscos) sem preencher nada por suposição.

## Quando usar

- Comando explícito `/spec-new` (com ou sem título).
- Usuário pede para criar uma nova spec ou abrir uma feature.
- Necessidade de registrar uma mudança nova de forma estruturada e testável.

## Conteúdo

- `SKILL.md` — fluxo de criação, ordem das seções, comportamento esperado (uma seção por vez, critérios testáveis) e anti-padrões.
- `references/spec.template.md` — template do `spec.md` (problema, objetivo, escopo, cenários, critérios, NFRs, riscos, perguntas em aberto).

## Relação com outras skills

Primeira skill do ciclo de uma SPEC, alimentada pelo roadmap do `app-kickoff` ou pela memória do `project-onboard`. Não gera plano nem tarefas: app-kickoff/project-onboard → spec-new → spec-review → spec-plan → spec-tasks → implementação.
