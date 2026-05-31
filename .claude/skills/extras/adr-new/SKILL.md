---
name: adr-new
description: Cria um Architecture Decision Record (ADR) a partir do template, ajudando a articular contexto, opções, decisão e consequências.
---

# adr-new

Use quando o usuário pedir pra **registrar uma decisão arquitetural**, **abrir um ADR**, **documentar uma escolha de design** importante.

## Quando ADR faz sentido

- Decisão difícil de reverter (escolha de framework, padrão arquitetural, abordagem de persistência).
- Decisão controversa onde quem chegar depois pode se perguntar "por que assim?".
- Trade-off explícito entre opções com peso parecido.

**NÃO** abrir ADR pra:
- Detalhe de implementação (ex: nome de variável, ordem de parâmetros).
- Decisão trivial sem alternativas reais.
- Solução de bug.

## O que faz

1. Pergunta:
   - Título da decisão em uma frase (deve começar com verbo: "Usar...", "Adotar...", "Migrar de X para Y").
   - Spec relacionada (se houver): SPEC-NNN.
   - Pasta de destino — default `.spec/archive/adr/` se o template está sendo usado standalone, ou `docs/adr/` no projeto destino.
2. Detecta próximo `ADR-<NNN>`.
3. Cria `<pasta>/ADR-<NNN>-<slug>.md` baseado em `.spec/templates/adr.template.md`.
4. Guia o usuário pelas seções:
   - **Contexto**: forças em jogo
   - **Decisão**: uma frase começando com "Vamos..."
   - **Opções consideradas**: mínimo 2 + opção "manter status quo"
   - **Consequências**: positivas, negativas, neutras
   - **Validação**: como saberemos se foi acertada (métrica ou data de revisão)

## Heurísticas

- Cada opção precisa de **prós E contras**. Se uma opção só tem prós, você não pensou direito nela.
- "Manter status quo" sempre é opção implícita — torne explícita.
- Decisão deve ser frase declarativa, não pergunta nem hedging.
- Se a decisão tem prazo de revisão, agendar (ex: "revisar em 6 meses ou se atingirmos X usuários").

## Como invocar

```
/adr-new
/adr-new "Adotar Signal Store em vez de NgRx clássico"
```

## Saída

- Caminho do ADR criado.
- Lembrete pra atualizar `status` quando aprovado/rejeitado.
- Se a ADR é consequência de uma spec, sugerir adicionar link na seção "Decisões arquiteturais" do plan.md.
