# Checklist de Code Review

> Use em todo PR. Não é exaustivo — adapte por projeto. O objetivo é forçar **pausa deliberada** antes de aprovar.

## Spec & Plano

- [ ] PR linka a spec correspondente em `.spec/changes/`
- [ ] Mudanças implementam exatamente o que está na spec — nada a mais, nada a menos
- [ ] Mudanças fora do escopo da spec são justificadas em comentário ou movidas para outra spec
- [ ] Critérios de aceitação são verificáveis pelos testes adicionados

## Correção e clareza

- [ ] Código faz o que o nome diz fazer
- [ ] Nomes descrevem intenção, não implementação
- [ ] Funções pequenas, com uma responsabilidade clara
- [ ] Sem código morto (imports não usados, branches inalcançáveis, TODOs sem dono)
- [ ] Comentários explicam **por quê**, não **o quê**

## Testes

- [ ] Testes cobrem critérios de aceitação da spec
- [ ] Testes cobrem caminhos de erro, não só o happy path
- [ ] Testes não testam implementação interna — testam comportamento observável
- [ ] Nenhum teste skipado/comentado sem justificativa em comentário
- [ ] Mocks somente em fronteiras (HTTP, BD externo); nada de mockar a própria camada que está sendo testada

## Frontend (Angular)

- [ ] Componentes `standalone` + `OnPush`
- [ ] Inputs/outputs tipados, sem `any`
- [ ] Estado em signals ou store, **não** em fields mutáveis
- [ ] Sem `subscribe` em template/componente sem `async` ou `takeUntilDestroyed`
- [ ] Templates não fazem `*ngIf` aninhado em mais de 2 níveis sem extrair componente
- [ ] Sem chamadas diretas a `console.*` no código final (usar `LoggerService`)
- [ ] **Em monorepo**: imports cruzando libs usam `@lib/...`, nunca path relativo

## Design responsivo (todo PR de UI)

- [ ] CSS é **mobile-first** (`min-width` em media queries, não `max-width`)
- [ ] Testado em **4 viewports**: 360px, 768px, 1024px, 1440px (screenshot ou descrição no PR)
- [ ] Sem overflow horizontal em nenhum viewport
- [ ] Tipografia usa unidades relativas (`rem`, `clamp`), não `px` fixo
- [ ] Touch targets (botões, ícones clicáveis) ≥ 44px em mobile
- [ ] Imagens com `srcset`/`<picture>` quando aplicável; `loading="lazy"` fora do above-the-fold
- [ ] Breakpoints usados são os tokens do projeto (`$bp-sm/md/lg/xl`), não valores hard-coded
- [ ] Navegação por teclado funciona (Tab/Shift+Tab/Enter/Esc)

## Backend (Spring)

- [ ] DTOs separados de Entities; sem expor JPA entity em response
- [ ] Validação `@Valid` aplicada nos endpoints com input estruturado
- [ ] Erros de domínio mapeados em `@RestControllerAdvice` global, não tratados ad-hoc
- [ ] Transações no nível certo (`@Transactional` no service, não no controller)
- [ ] Sem N+1 query óbvio (verifique `fetch` strategies, `@EntityGraph` quando aplicável)
- [ ] Migrations Flyway são forward-only e idempotentes onde possível

## API e contrato

- [ ] OpenAPI atualizado e versionado
- [ ] Cliente TS regenerado se contrato mudou
- [ ] Versionamento de path (`/api/v1`) preservado; **nunca** quebra compatível em `v1`

## Segurança

- [ ] Sem segredos commitados (chaves, tokens, senhas)
- [ ] Inputs validados antes de tocar persistência ou serviços externos
- [ ] Autorização verificada por endpoint (não confiar só em auth global)
- [ ] Logs não vazam dados sensíveis (PII, tokens, senhas)

## Performance e observabilidade

- [ ] Logs em pontos de decisão importantes (estruturados, com correlação)
- [ ] Métricas adicionadas para operações novas críticas
- [ ] Sem operação O(n) virando O(n²) por loop aninhado em coleção grande
- [ ] Caching considerado onde apropriado e documentado

## Rollout

- [ ] Migrations e código compatíveis (deploy de migration antes do código que depende dela)
- [ ] Feature flag definida se a mudança é arriscada
- [ ] Plano de rollback claro
