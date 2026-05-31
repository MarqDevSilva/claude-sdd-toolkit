---
name: spec-review
description: Revisa uma spec ou plano checando completude, ambiguidades, critérios testáveis, NFRs relevantes e consistência com as convenções do projeto. Use quando o usuário pedir pra revisar uma spec, dar uma segunda opinião antes de aprovar ou checar se a spec está completa.
---

# spec-review

Use quando o usuário pedir pra **revisar uma spec**, **dar uma segunda opinião antes de aprovar**, **checar se a spec está completa** ou similar.

## O que faz

1. Pergunta qual SPEC revisar (ou aceita ID via argumento).
2. Lê `spec.md` e `plan.md` (se existir) da pasta da SPEC.
3. Roda checklist de revisão:

### Checklist de completude (spec)

- [ ] Problema separa **o quê** e **por que importa**, sem solução embutida
- [ ] Objetivo é mensurável e tem **uma** frase
- [ ] Escopo lista também o **fora** (não-objetivos)
- [ ] Cada critério de aceitação é testável (sem "rápido", "fácil", "bom")
- [ ] Cenários usam Dado/Quando/Então e referenciam personas nomeadas
- [ ] NFRs selecionados são **relevantes** (apenas os que se aplicam à feature)
- [ ] Termos novos estão definidos ou apontados pro glossário do projeto
- [ ] Perguntas em aberto estão explícitas
- [ ] Status no frontmatter coerente

### Checklist de completude (plan, se existir)

- [ ] Estratégia técnica justificada em 3-5 linhas
- [ ] Componentes afetados cobertos com tipo de mudança claro
- [ ] Contrato API definido ou linkado
- [ ] Modelo de dados (se aplicável) descrito
- [ ] Estratégia de testes cobre unit + integração mínima
- [ ] Rollout/rollback documentado
- [ ] Riscos técnicos têm mitigação

### Checklist de consistência

- [ ] Não contradiz princípios/convenções do projeto (constitution, conventions — se o projeto os mantiver)
- [ ] Decisões arquiteturais geraram ADR (ou justificativa de não ter)

> Para revisar o **PR de implementação** (não a spec), use a [checklist de code review](references/review-checklist.md).

## Como invocar

```
/spec-review
/spec-review SPEC-007
```

## Forma da resposta

- Apontar **problemas concretos** com citação do trecho.
- Distinguir **bloqueante** vs **sugestão**.
- No final, parecer único: `Aprovar`, `Aprovar com ressalvas`, `Pedir revisão`.
