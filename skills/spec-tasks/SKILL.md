---
name: spec-tasks
description: Quebra o plano técnico (plan.md) em tarefas executáveis pequenas, ordenadas por dependência, com critério de pronto por tarefa.
---

# spec-tasks

Use quando o usuário pedir pra **quebrar o plano em tarefas**, **gerar TODO list da feature**, **criar lista executável** a partir de um plan.md.

## Pré-requisito

Existir `plan.md` em `.spec/changes/SPEC-<NNN>-*/`. Se só existir `spec.md`, sugerir rodar `/spec-plan` primeiro.

## O que faz

1. Lê `spec.md` + `plan.md` da pasta da SPEC indicada.
2. Cria `tasks.md` usando [references/tasks.template.md](references/tasks.template.md).
3. Decompõe o trabalho em fases (Fundação → Backend → Frontend → Observabilidade/Finalização).
4. Cada tarefa:
   - Tem prefixo `(F)`, `(B)`, `(I)`, `(D)` indicando frente.
   - É pequena (≤ meio dia de trabalho ideal).
   - Tem critério de pronto implícito ou explícito.
   - Lista dependências (ex: "depende de migration aplicada").
5. Garante ordem topológica: nada que dependa de X aparece antes de X.

## Como invocar

```
/spec-tasks
/spec-tasks SPEC-007
```

## Heurísticas de decomposição

- **Contrato antes de implementação**: OpenAPI + cliente TS gerado antes das duas pontas.
- **Migration antes de código de domínio**.
- **Slice tests antes de integração**.
- **Observabilidade no final**, mas não esquecida — sempre tem fase dedicada.
- Tarefa que demora mais de meio dia? Quebrar mais.

## Como NÃO usar

- Não duplicar conteúdo do plan no tasks. Tasks são **acionáveis**, plan é **descritivo**.
- Não criar tarefas vagas tipo "implementar feature X". Sempre algo específico.

## Saída final

- `tasks.md` criado.
- Total de tarefas estimadas por frente (front, back, infra, docs).
- Sugestão de qual tarefa começar primeiro.
