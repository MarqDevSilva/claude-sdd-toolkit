# spec-tasks

> Quebra o plano técnico (`plan.md`) em tarefas executáveis, ordenadas por dependência.

Skill que decompõe um `plan.md` aprovado em `tasks.md`. Organiza o trabalho em fases (Fundação → Backend → Frontend → Observabilidade/Finalização), com tarefas pequenas (≤ meio dia), prefixadas por frente `(F)/(B)/(I)/(D)`, com critério de pronto e dependências em ordem topológica.

## Quando usar

- Comando explícito `/spec-tasks` (com ou sem ID da SPEC).
- Usuário pede para quebrar o plano em tarefas ou gerar a TODO list da feature.
- Existe um `plan.md` pronto para virar lista executável.

## Conteúdo

- `SKILL.md` — pré-requisitos, regras de decomposição (contrato antes da implementação, migration antes do domínio) e anti-padrões.
- `references/tasks.template.md` — template do `tasks.md` (fases, tarefas, prefixos de frente, dependências).

## Relação com outras skills

Última skill antes da implementação; consome o `plan.md` gerado por `spec-plan`: spec-new → spec-review → spec-plan → spec-tasks → implementação.
