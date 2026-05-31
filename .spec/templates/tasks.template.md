---
spec: SPEC-<NNN>
plan: plan.md
status: rascunho   # rascunho | em-execucao | concluido
criado-em: <YYYY-MM-DD>
---

# Tarefas — SPEC-<NNN>

> Tarefas pequenas (≤ meio dia), com critério de pronto explícito, ordem de execução clara.

## Legenda

- `[ ]` pendente | `[x]` concluído | `[~]` em andamento | `[!]` bloqueado
- `(F)` Frontend | `(B)` Backend | `(I)` Infra/DB | `(D)` Docs/Spec

## Fase 1 — Fundação (contratos e schema)

- [ ] (B) Definir entidade `X` em `domain/`
- [ ] (B) Criar migration Flyway `V<timestamp>__create_x.sql`
- [ ] (B) Criar `XRepository` + teste com `@DataJpaTest`
- [ ] (D) Atualizar OpenAPI spec do endpoint `/api/v1/x`
- [ ] (F) Gerar client TS a partir do OpenAPI atualizado

## Fase 2 — Backend

- [ ] (B) Implementar `XService` (regras de domínio)
- [ ] (B) Implementar `XController` (POST + GET)
- [ ] (B) Mapper `XMapper` (MapStruct)
- [ ] (B) Slice test `@WebMvcTest XController`
- [ ] (B) Teste de integração com Testcontainers

## Fase 3 — Frontend

- [ ] (F) Criar feature module `features/x/`
- [ ] (F) Criar `XService` consumindo client gerado
- [ ] (F) Criar `XStore` (signal store) com estado da feature
- [ ] (F) Implementar página `XListPage`
- [ ] (F) Implementar página `XDetailPage`
- [ ] (F) Testes unitários (Jest)

## Fase 4 — Observabilidade e finalização

- [ ] (B) Adicionar logs estruturados em pontos críticos
- [ ] (B) Adicionar métricas Micrometer
- [ ] (D) Documentar feature flag e rollout
- [ ] (D) Atualizar README/changelog
- [ ] (D) Mover spec para `.spec/archive/` ao concluir

## Critério de pronto da spec

A spec só vai pro `.spec/archive/` quando:

- [ ] Todos os critérios de aceitação validados em ambiente real
- [ ] Cobertura de testes nos componentes novos ≥ alvo do projeto
- [ ] Sem perguntas em aberto na spec
- [ ] Plano de rollback testado (mesmo que mentalmente)
- [ ] Documentação atualizada
