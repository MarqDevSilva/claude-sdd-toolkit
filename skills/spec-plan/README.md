# spec-plan

> Gera o plano técnico (`plan.md`) a partir de uma spec aprovada.

Skill que transforma uma `spec.md` aprovada no plano de implementação. Mapeia componentes afetados (front/back/DB), contrato API, modelo de dados, estratégia de testes, observabilidade, rollout/rollback e ADRs derivados, seguindo a arquitetura e convenções existentes quando há `.spec/memory/`.

## Quando usar

- Comando explícito `/spec-plan` (com ou sem ID da SPEC).
- Usuário pede para planejar a implementação ou detalhar como construir uma feature.
- Existe uma `spec.md` aprovada (ou em revisão) pronta para virar plano técnico.

## Conteúdo

- `SKILL.md` — pré-requisitos, seções do plano e heurísticas (exigir migration, contrato API, ADRs, alvos de p95).
- `references/plan.template.md` — template do `plan.md` (abordagem, componentes, dados, testes, rollout, riscos).
- `references/api-contract.template.md` — template do `api-contract.md` para contratos complexos.

## Relação com outras skills

Vem depois de `spec-new`/`spec-review` (precisa de uma spec aprovada) e antes de `spec-tasks` (o plano é a entrada da decomposição): spec-new → spec-review → spec-plan → spec-tasks → implementação.
