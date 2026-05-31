---
name: spec-new
description: Cria uma nova spec em .spec/changes/ a partir do template, fazendo perguntas guiadas pra preencher problema, escopo, critérios de aceitação e NFRs.
---

# spec-new

Use esta skill quando o usuário pedir pra **criar uma nova spec**, **abrir uma feature**, **registrar uma mudança nova** ou similar.

## O que faz

1. Pergunta o título curto da feature/mudança.
2. Detecta o próximo `SPEC-<NNN>` lendo o que já existe em `.spec/changes/` e `.spec/archive/`.
3. Cria a pasta `.spec/changes/SPEC-<NNN>-<slug>/` com `spec.md` baseado em `.spec/templates/spec.template.md`.
4. Guia o usuário com perguntas pra preencher cada seção, **uma seção por vez**:
   - Problema (quem, dor, por que agora)
   - Objetivo (resultado mensurável)
   - Escopo (dentro/fora)
   - Personas + cenários (usar `.spec/shared/personas.md`)
   - Critérios de aceitação (testáveis)
   - NFRs (selecionar de `.spec/shared/nfr-catalog.md`)
   - Riscos e premissas
   - Perguntas em aberto
5. Não preenche nada por suposição — quando faltar info, **pergunta**.
6. Ao final, atualiza o frontmatter (`status: rascunho`, datas, autor).

## Como invocar

```
/spec-new
/spec-new "fluxo de exportação de relatórios"
```

## Comportamento esperado

- Uma seção por vez. Nada de despejar a spec inteira pra preencher.
- Sugerir reformulações quando o usuário escrever critério ambíguo (ex: "rápido" → "p95 < 300ms").
- Lembrar de checar [glossário](../../.spec/memory/glossary.md) — se aparecer termo novo, propor adicioná-lo.
- Não criar plan.md nem tasks.md — isso é trabalho do `/spec-plan` e `/spec-tasks`.

## Saída final

- `.spec/changes/SPEC-<NNN>-<slug>/spec.md` criado e preenchido.
- Resumo curto pro usuário: ID, caminho do arquivo, próximas perguntas em aberto (se houver).
