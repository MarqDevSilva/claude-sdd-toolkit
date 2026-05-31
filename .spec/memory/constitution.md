# Constituição do Projeto

> Princípios **invioláveis** que orientam toda decisão técnica deste projeto.
> Edite por projeto, mas não os contradiga sem registrar um ADR explicando o porquê.

## 1. Princípios de produto

- **Clareza antes de código**: nenhuma implementação começa sem uma spec em `.spec/changes/` aprovada.
- **Pequenos incrementos**: cada feature deve ser entregável de forma independente; nada de "big bang".
- **Reversibilidade**: toda mudança não-trivial precisa de plano de rollback documentado.

## 2. Princípios de engenharia

- **Tipagem forte sempre**: TypeScript estrito no front, Java com tipos explícitos no back. `any` e `Object` são proibidos sem justificativa em ADR.
- **Testes na borda do comportamento**: cobre intenção, não implementação. Testes que travam refactor saudável devem ser refatorados, não preservados.
- **Convenções > preferências individuais**: quando há conflito de estilo, vence o que está em [conventions.md](conventions.md).
- **Erros explícitos**: nada de catch silencioso. Todo erro tratado tem destino claro (log estruturado, métrica, resposta ao usuário).

## 3. Princípios de arquitetura

- **Domínio no centro**: regras de negócio não dependem de framework. Spring/Angular são detalhe de entrega.
- **Contratos antes de integração**: API entre front e back é definida em `.spec/templates/api-contract.template.md` (OpenAPI) **antes** da implementação dos dois lados.
- **Boundary explícita**: módulos têm fronteiras definidas; cruzar fronteira sem passar por contrato é falha de design.

## 4. Princípios de UI

- **Mobile-first sempre**: toda tela é projetada e testada primeiro em 360px de largura. Desktop é **expansão**, não o ponto de partida.
- **Responsivo é requisito, não nice-to-have**: nenhum componente de UI vai pra `main` sem suportar viewports de 360px, 768px, 1024px e 1440px. Tela quebrada em mobile é bug bloqueante.
- **Acessibilidade desde o primeiro commit**: navegação por teclado funciona, contraste mínimo respeitado, touch targets ≥ 44px em mobile. A11y depois do MVP custa 10x mais.

## 5. O que NÃO fazemos

- Não introduzimos abstração para "caso futuro hipotético" — só quando há 3+ usos concretos.
- Não fazemos refactor especulativo no meio de uma feature; abrir spec separada.
- Não fazemos merge sem revisão (mesmo em projetos solo: revise contra esta constituição antes de mergear).

## 6. Como evoluir esta constituição

Mudanças aqui passam por ADR. Veja [.spec/templates/adr.template.md](../templates/adr.template.md).
