# spec-review

> Revisa uma spec ou plano com checklist de completude, ambiguidades e consistência.

Skill de segunda opinião antes de aprovar. Lê `spec.md` e `plan.md` (e a memória do projeto, se existir) e roda checklists de completude (spec e plan) e de consistência, apontando problemas concretos com citação e distinguindo bloqueante de sugestão. Fecha com um parecer único.

## Quando usar

- Comando explícito `/spec-review` (com ou sem ID da SPEC).
- Usuário pede para revisar uma spec ou checar se está completa.
- Necessidade de uma segunda opinião antes de aprovar uma spec/plano.

## Conteúdo

- `SKILL.md` — checklists de completude (spec/plan) e de consistência, forma da resposta e parecer final (Aprovar / Aprovar com ressalvas / Pedir revisão).
- `references/review-checklist.md` — checklist de code review para o PR de implementação (não a spec).

## Relação com outras skills

Etapa de gate de qualidade do fluxo. Roda tipicamente após `spec-new` (revisar a spec) e/ou após `spec-plan` (revisar o plano), antes de seguir adiante: spec-new → spec-review → spec-plan → spec-tasks → implementação.
