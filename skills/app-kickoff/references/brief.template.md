---
status: rascunho   # rascunho | aprovado
versao: 1
criado-em: <YYYY-MM-DD>
atualizado-em: <YYYY-MM-DD>
---

# Brief — Nome do Sistema

> Template para `.spec/discovery/brief.md`. Estrutura usada pelo skill [`/app-kickoff`](../SKILL.md) na Fase 1.
> Foundational, leve. Não inflar — detalhamento por módulo mora nos `module_<nome>.md`.

## 1. Visão de produto

> 2-3 frases. O que o sistema faz, pra quem, e qual o valor entregue.

...

## 2. Atores e perfis

> Quem interage com o sistema. Cada perfil terá funcionalidades específicas.

- **Admin**: ...
- **Usuário final**: ...
- **Integrações externas** (se aplicável): ...

## 3. Arquitetura macro

- **Multi-tenant?** sim/não. Se sim, como tenants são isolados (RLS, schema-per-tenant, etc.)?
- **Quem cadastra quem?** (auto-cadastro / convite / importação)
- **Stack pretendido**: documentar o stack escolhido ou anotar divergências em relação ao padrão do projeto.
- **Topologia**: monolito / monorepo Angular / múltiplos apps?

## 4. Fases de entrega

> Marcar explicitamente o que cabe em cada fase. Cada RF/RNF nos módulos vai referenciar uma fase.

- **Fase 0 (Fundação)**: setup, CI, observabilidade, error handling, auth scaffold.
- **Fase 1 (MVP)**: ...
- **Fase 2**: ...
- **Futuro** (fora do escopo atual): ...

## 5. Lista de módulos funcionais

> Os módulos que serão detalhados na Fase 2 (`modules.md`).

1. Módulo 1 — Nome
2. Módulo 2 — Nome
3. ...

## 6. Restrições conhecidas

- **Compliance / legal**: LGPD, regulação setorial, etc.
- **Performance**: alvos de latência/throughput conhecidos.
- **Integrações obrigatórias**: APIs externas que o sistema precisa consumir/expor.
- **Prazo / orçamento**: se já houver.

## 7. Decisões estruturais salvas em memory

> Lista de memórias do projeto destino populadas a partir deste brief.

- [ ] `project_overview.md` — visão de produto + atores
- [ ] `project_phases.md` — fases de entrega e o que cabe em cada
- [ ] `project_stack.md` — divergências/escolhas de stack do projeto
