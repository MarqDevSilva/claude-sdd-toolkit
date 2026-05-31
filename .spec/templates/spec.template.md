---
id: SPEC-<NNN>
titulo: <Título curto e descritivo>
status: rascunho   # rascunho | em-revisao | aprovada | em-execucao | concluida | arquivada
autor: <nome>
criada-em: <YYYY-MM-DD>
atualizada-em: <YYYY-MM-DD>
relacionadas: []   # outras specs/ADRs relacionados
---

# SPEC-<NNN>: <Título>

## 1. Problema

> **O QUÊ** estamos resolvendo e **POR QUE** importa. Sem solução aqui.

- Quem é afetado?
- Qual a dor atual?
- Por que agora?

## 2. Objetivo

> Resultado mensurável esperado. Uma frase, no máximo duas.

## 3. Escopo

### Dentro

- ...

### Fora (não-objetivos)

- ...

## 4. Usuários e cenários

> Use [shared/personas.md](../shared/personas.md). Liste cenários concretos, não abstratos.

### Persona principal: <nome>

**Cenário 1**: <nome curto>
- **Dado** que ...
- **Quando** ...
- **Então** ...

## 5. Critérios de aceitação

> Lista numerada, testável, sem ambiguidade. Cada item vira (no mínimo) um teste.

1. [ ] ...
2. [ ] ...

## 6. Requisitos não-funcionais

> Selecione do [shared/nfr-catalog.md](../shared/nfr-catalog.md). Inclua **apenas os relevantes**.

| NFR | Alvo | Como medir |
|-----|------|------------|
| Performance | p95 < 300ms | métrica X |
| Segurança | Autenticação obrigatória | revisão manual + teste de auth |

## 7. Riscos e premissas

| Item | Tipo | Mitigação |
|------|------|-----------|
| ... | risco/premissa | ... |

## 8. Perguntas em aberto

- [ ] ...

## 9. Referências

- [Constituição](../memory/constitution.md)
- [Stack](../memory/tech-stack.md)
- ADRs relevantes: ...
- Links externos: ...
