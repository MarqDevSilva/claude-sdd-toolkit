---
name: spec-new
description: Cria uma nova spec em .spec/changes/ a partir do template, fazendo perguntas guiadas pra preencher problema, escopo, critérios de aceitação e NFRs. Use quando o usuário pedir pra criar uma nova spec, abrir uma feature ou registrar uma mudança nova.
---

# spec-new

Use esta skill quando o usuário pedir pra **criar uma nova spec**, **abrir uma feature**, **registrar uma mudança nova** ou similar.

## O que faz

1. Pergunta o título curto da feature/mudança.
2. Detecta o próximo `SPEC-<NNN>` lendo o que já existe em `.spec/changes/` e `.spec/archive/` (numeração de 3 dígitos, sequencial; se nenhuma existir, começa em `SPEC-001`).
3. Cria a pasta `.spec/changes/SPEC-<NNN>-<slug>/` com `spec.md` baseado em [references/spec.template.md](references/spec.template.md).
4. Guia o usuário com perguntas pra preencher cada seção, **uma seção por vez**, na ordem do template:
   - **Problema** (quem é afetado, qual a dor, por que agora) — sem solução embutida.
   - **Objetivo** (resultado mensurável, uma frase no máximo duas).
   - **Escopo** (o que está dentro **e** o que está fora / não-objetivos).
   - **Usuários e cenários** (persona principal + cenários concretos em Dado/Quando/Então).
   - **Critérios de aceitação** (lista numerada, cada item testável).
   - **Requisitos não-funcionais** (apenas os relevantes — performance, segurança, etc. — com alvo numérico e forma de medir).
   - **Riscos e premissas**.
   - **Perguntas em aberto**.
5. Não preenche nada por suposição — quando faltar info, **pergunta**.
6. Ao final, atualiza o frontmatter (`status: rascunho`, `criada-em`, `atualizada-em`, `autor`).

## Como invocar

```
/spec-new
/spec-new "fluxo de exportação de relatórios"
```

## Comportamento esperado

- **Uma seção por vez.** Nada de despejar a spec inteira pra preencher de uma vez.
- Sugerir reformulações quando o usuário escrever critério ambíguo: "rápido" → "p95 < 300ms", "fácil" → critério observável.
- Cada cenário em Dado/Quando/Então, referenciando uma persona concreta (não "o usuário" genérico).
- NFRs: incluir **apenas os relevantes** à feature, cada um com alvo mensurável e como medir. Não copiar catálogo inteiro.
- Não criar `plan.md` nem `tasks.md` — isso é trabalho do `/spec-plan` e `/spec-tasks`.

## Como NÃO usar

- Não embutir solução técnica na seção de Problema (isso é `/spec-plan`).
- Não aceitar critério de aceitação não-testável (sem "bom", "rápido", "intuitivo" sem métrica).
- Não pular a seção "Fora (não-objetivos)" do escopo — delimitar é parte do valor da spec.

## Saída final

- `.spec/changes/SPEC-<NNN>-<slug>/spec.md` criado e preenchido.
- Resumo curto pro usuário: ID, caminho do arquivo (link clicável), perguntas em aberto (se houver) e próximo passo sugerido (`/spec-review` ou `/spec-plan`).
