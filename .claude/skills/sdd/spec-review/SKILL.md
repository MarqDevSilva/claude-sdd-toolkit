---
name: spec-review
description: Revisa uma spec ou plano checando completude, ambiguidades, critérios testáveis, NFRs relevantes e consistência com constitution/conventions.
---

# spec-review

Use quando o usuário pedir pra **revisar uma spec**, **dar uma segunda opinião antes de aprovar**, **checar se a spec está completa** ou similar.

## O que faz

1. Pergunta qual SPEC revisar (ou aceita ID via argumento).
2. Lê `spec.md`, `plan.md` (se existir), `.spec/memory/constitution.md`, `.spec/memory/conventions.md`, `.spec/shared/nfr-catalog.md`, `.spec/memory/glossary.md`.
3. Roda checklist de revisão:

### Checklist de completude (spec)

- [ ] Problema separa **o quê** e **por que importa**, sem solução embutida
- [ ] Objetivo é mensurável e tem **uma** frase
- [ ] Escopo lista também o **fora** (não-objetivos)
- [ ] Cada critério de aceitação é testável (sem "rápido", "fácil", "bom")
- [ ] Cenários usam Dado/Quando/Então e referenciam personas existentes
- [ ] NFRs selecionados são **relevantes** (sem copy/paste do catálogo todo)
- [ ] Termos usados estão no glossário; se não, adicionar
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

- [ ] Não contradiz [constitution](../../.spec/memory/constitution.md)
- [ ] Segue [conventions](../../.spec/memory/conventions.md)
- [ ] Decisões arquiteturais geraram ADR (ou justificativa de não ter)

## Como invocar

```
/spec-review
/spec-review SPEC-007
```

## Forma da resposta

- Apontar **problemas concretos** com citação do trecho.
- Distinguir **bloqueante** vs **sugestão**.
- No final, parecer único: `Aprovar`, `Aprovar com ressalvas`, `Pedir revisão`.
