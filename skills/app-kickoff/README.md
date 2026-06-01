# app-kickoff

> Conduz a descoberta inicial de um app novo (greenfield) e gera os artefatos de discovery.

Skill para o kickoff de um produto do zero. Faz a descoberta de forma guiada (perguntas antes de escrever, um módulo por vez) e produz os artefatos sequenciais em `.spec/discovery/`: visão de produto, um arquivo por módulo, modelagem de entidades e roadmap de entrega.

## Quando usar

- Comando explícito `/app-kickoff` (com ou sem frase descritiva).
- Usuário descreve um sistema novo e lista módulos funcionais.
- Pedido para "iniciar projeto", "fazer descoberta" ou "documentar requisitos do zero".
- Necessidade de chegar até o roadmap de entregas, não apenas requisitos.

## Conteúdo

- `SKILL.md` — processo de descoberta em 4 fases (brief, módulos, entidades, roadmap), princípios e anti-padrões.
- `references/brief.template.md` — estrutura do `brief.md` (visão, atores, arquitetura macro, fases, módulos).
- `references/modules.template.md` — estrutura de cada `module_<nome>.md`.
- `references/entities.template.md` — decisões transversais + modelagem conceitual/técnica.
- `references/roadmap.template.md` — fases de entrega e SPECs sugeridas.

## Relação com outras skills

Ponto de entrada do fluxo SDD para projetos novos (alternativa a `project-onboard`, que é para projetos existentes). O roadmap gerado aqui alimenta o `spec-new` para abrir a primeira SPEC: app-kickoff → spec-new → spec-review → spec-plan → spec-tasks → implementação.
