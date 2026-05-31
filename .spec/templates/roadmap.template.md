---
brief: .spec/discovery/brief.md
modulos: .spec/discovery/module_*.md
entidades: .spec/discovery/entities.md
status: rascunho   # rascunho | aprovado
versao: 1
criado-em: <YYYY-MM-DD>
---

# Roadmap de Execução — Nome do Sistema

> Template para `.spec/discovery/roadmap.md`. Estrutura usada pelo skill [`/app-kickoff`](../../.claude/skills/sdd/app-kickoff/SKILL.md) na Fase 4.
> Ordem de implementação derivada do `brief.md` + arquivos `module_<nome>.md` + `entities.md`.

## Critérios usados (nesta ordem)

1. **Desbloqueio**: módulos que destravam outros vão antes (auth quase sempre).
2. **Risco técnico**: atacar dúvida grande cedo, pra descobrir cedo o que não funciona.
3. **Valor entregue**: depois do desbloqueado, caminho mais curto até "usuário ver algo funcionando".
4. **Reversibilidade**: schema/contrato grandes vão cedo; coisas refatoráveis depois.

---

## Fase 0 — Fundação técnica

> Não entrega valor de produto, mas viabiliza todas as outras fases.

- [ ] Setup do workspace (back + front, monorepo se aplicável — ver [angular-monorepo.md](../shared/angular-monorepo.md))
- [ ] CI rodando lint + test em PR
- [ ] Banco PostgreSQL + Flyway inicial (ver schema da Etapa 2 em `.spec/discovery/entities.md`)
- [ ] Auth scaffold (login mínimo, mesmo que mock) — derivado de `.spec/discovery/module_auth.md`
- [ ] Observabilidade: Logback + Sentry + Actuator (ver [observability.md](../shared/observability.md))
- [ ] Error handling: `ErrorCode` + `DomainException` + handler global (ver [error-handling.md](../shared/error-handling.md))
- [ ] OpenAPI + cliente TS gerado (pipeline funcionando, mesmo com 1 endpoint dummy)
- [ ] Deploy de preview funcionando

**Critério de pronto da fase**: PR de exemplo abre preview deployado com login.

---

## Fase 1 — `Módulo X (foundational)`

> Referência: [.spec/discovery/module_<x>.md](../discovery/module_<x>.md)
>
> **Por que primeiro**: ...
>
> **Riscos atacados**: ...

**Specs sugeridas** (abrir via `/spec-new`):

- [ ] SPEC-001: <funcionalidade derivada de RF-01, RF-02>
- [ ] SPEC-002: <funcionalidade derivada de RF-03, RF-04>
- [ ] SPEC-003: <funcionalidade derivada de RF-05>

**Critério de pronto da fase**: todos RFs do módulo implementados + RNFs medidos.

---

## Fase 2 — `Próximo módulo`

> Referência: [.spec/discovery/module_<y>.md](../discovery/module_<y>.md)
>
> **Por que agora**: ...

**Specs sugeridas**:

- [ ] SPEC-004: ...
- [ ] SPEC-005: ...

**Critério de pronto da fase**: ...

---

## Fase N — `Último módulo`

(repete)

---

## Marcos

| Marco | O que valida | Quando (estimativa) |
|-------|--------------|---------------------|
| MVP fechado | Módulos 1, 2, 3 com RFs e RNFs atendidos | ... |
| Beta com usuários reais | NFRs de performance, segurança e LGPD validados | ... |
| GA | Todos módulos do escopo + observabilidade madura | ... |

## Riscos transversais

| Risco | Probabilidade | Impacto | Mitigação |
|-------|---------------|---------|-----------|
| ... | baixa/média/alta | baixo/médio/alto | ... |

## Decisões pendentes que travam o roadmap

- [ ] ...
