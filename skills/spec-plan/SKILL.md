---
name: spec-plan
description: Gera o plano técnico (plan.md) a partir de uma spec aprovada, mapeando componentes afetados, contrato API, modelo de dados, testes e rollout.
---

# spec-plan

Use quando o usuário pedir pra **planejar a implementação** de uma spec existente, **gerar o plano técnico**, **detalhar como vamos construir** algo.

## Pré-requisito

Existir uma `spec.md` em `.spec/changes/SPEC-<NNN>-<slug>/` com status `aprovada` (ou `em-revisao` se o usuário insistir).

Se não existir spec, **redirecionar** pro `/spec-new` — não inventar plano sem spec.

## O que faz

1. Pergunta qual SPEC (ou detecta se só houver uma em rascunho ativo).
2. Lê `.spec/changes/SPEC-<NNN>-*/spec.md`. **Se existir** `.spec/memory/architecture.md` e/ou `.spec/memory/conventions.md` (gerados por `/project-onboard`), lê também — o plano deve **seguir a arquitetura e convenções existentes**, não inventar um padrão novo.
3. Cria `plan.md` na mesma pasta da spec, usando [references/plan.template.md](references/plan.template.md).
4. Preenche guiando o usuário pelas seções:
   - Visão geral da abordagem (estratégia + por quê)
   - Componentes afetados (front/back/DB), tabela por área
   - Contrato API (resumo; se complexo, criar `api-contract.md` paralelo a partir de [references/api-contract.template.md](references/api-contract.template.md))
   - Modelo de dados (mermaid quando útil)
   - Estratégia de testes
   - Observabilidade, segurança, performance
   - Rollout e rollback (feature flag? migration reversível?)
   - ADRs derivados (registrar decisão arquitetural quando houver)
   - Riscos técnicos

## Como invocar

```
/spec-plan
/spec-plan SPEC-007
```

## Heurísticas

- Se a feature toca banco: **exigir** migration listada e estratégia de rollback.
- Se toca contrato API: **exigir** entrada de OpenAPI atualizada e cliente TS regerado nas tasks.
- Se introduz nova lib/dependência: **sugerir** registrar a decisão em ADR.
- Se p95 importa: **exigir** alvo numérico em NFR.
- Se há `.spec/memory/architecture.md`: os componentes afetados devem **encaixar nos módulos/camadas existentes**; qualquer divergência do padrão atual precisa de justificativa explícita.

## Saída final

- `plan.md` criado ao lado da `spec.md`.
- Lista de decisões pendentes que viraram ADRs sugeridos.
- Resumo dos riscos técnicos identificados.
