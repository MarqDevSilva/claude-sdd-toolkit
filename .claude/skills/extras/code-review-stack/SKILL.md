---
name: code-review-stack
description: Faz code review do diff atual aplicando o checklist específico Angular 18+ / Java Spring de .spec/templates/review-checklist.md.
---

# code-review-stack

Use quando o usuário pedir pra **revisar mudanças atuais**, **review do diff**, **checar PR localmente**, **segunda opinião antes de commit/push**.

## Pré-requisitos

- Repositório git com mudanças (staged, unstaged ou em branch).
- `.spec/templates/review-checklist.md` disponível (ou cópia equivalente no projeto).

## O que faz

1. Detecta o diff a revisar:
   - Default: `git diff` (working tree) + `git diff --cached` (staged).
   - Alternativa: `git diff main...HEAD` se em branch de feature.
   - Pergunta se houver ambiguidade.
2. Carrega:
   - `.spec/templates/review-checklist.md`
   - `.spec/memory/constitution.md`
   - `.spec/memory/conventions.md`
   - Spec relacionada se referenciada no commit/branch.
3. Aplica o checklist contra o diff, **uma seção por vez**:
   - Spec & plano (linka spec? respeita escopo?)
   - Correção e clareza
   - Testes
   - Frontend (Angular) — só se houver `.ts/.html/.scss` no diff
   - Backend (Spring) — só se houver `.java` no diff
   - API e contrato
   - Segurança
   - Performance e observabilidade
   - Rollout
4. Reporta findings categorizados:
   - **Bloqueante** (impede merge — bug, vulnerabilidade, quebra de contrato)
   - **Sugestão forte** (deveria mudar; explicar trade-off se preferir manter)
   - **Nit** (estilo, gosto pessoal — opcional)

## Heurísticas

- **Cite o trecho** com path + linha em cada finding.
- Não duplicar o que o linter já pega.
- Diferenciar bem **bloqueante** de **preferência** — ser explícito.
- Sugerir **a correção**, não só apontar o problema.
- Se o diff é grande (>500 linhas), perguntar se quer revisar por arquivo ou por área.

## Como invocar

```
/code-review-stack
/code-review-stack desde main
```

## Saída

- Lista de findings agrupados por categoria.
- Veredito final: `Aprovar`, `Aprovar com ressalvas`, `Pedir revisão`.
- Sugestão de próximo passo (corrigir e re-revisar; rodar testes específicos; etc).
