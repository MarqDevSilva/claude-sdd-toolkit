---
status: rascunho   # rascunho | aprovado
versao: 1
criado-em: <YYYY-MM-DD>
atualizado-em: <YYYY-MM-DD>
---

# Módulo — Nome do Módulo

> Template para `.spec/discovery/module_<nome>.md`. Estrutura usada pelo skill [`/app-kickoff`](../../.claude/skills/sdd/app-kickoff/SKILL.md) na Fase 2.
> **Um arquivo por módulo** (ex: `module_auth.md`, `module_clientes.md`, `module_dashboard.md`) — nunca concatenar.
> Numeração de RFs/RNFs/RNs é local ao arquivo (`RF-01`, `RF-02`...). Para referenciar entre módulos, use `module_<nome>.md#rf-01`.

## Visão Geral

[1 parágrafo: propósito do módulo, valor que entrega, contexto]

> ⚠️ **Fases aplicáveis**: o que entra na Fase 1, Fase 2, Fase Futura.

## Atores

- **Ator 1**: o que faz / o que vê
- **Ator 2**: o que faz / o que vê

## Conceitos-Chave

> Termos novos que aparecem nas seções abaixo — anotar pra sugerir no [glossário](../memory/glossary.md).

- **Termo 1**: definição
- **Termo 2**: definição

## Requisitos Funcionais

> Subseções agrupadas tematicamente quando útil.

- **RF-01**: ...
- **RF-02**: ...
- **RF-03**: ...

### Subtema (opcional)

- **RF-04**: ...
- **RF-05**: ...

## Requisitos Não Funcionais

> Use [shared/nfr-catalog.md](../shared/nfr-catalog.md) como ponto de partida.

- **RNF-01 (Performance)**: ...
- **RNF-02 (Segurança)**: ...
- **RNF-03 (LGPD)**: ...
- **RNF-04 (Disponibilidade)**: ...

## Regras de Negócio

- **RN-01**: ...
- **RN-02**: ...
- **RN-03**: ...

## Fluxos Principais

### Fluxo 1 — Nome do Fluxo

1. Ator inicia X
2. Sistema responde com Y
3. Ator confirma Z
4. Sistema persiste e notifica

**Exceções / Caminhos alternativos**:
- Se A, então B
- Se C, então D

### Fluxo 2 — Outro Fluxo

1. ...

## Integrações

| Com | Tipo | Direção | Pra quê |
|-----|------|---------|---------|
| Módulo Y (`module_y.md`) | chamada / evento | publica / consome | ... |
| Serviço externo | REST / webhook | consome / recebe | ... |

## Pontos em Aberto

- [ ] Decisão pendente sobre X.
- [ ] Falta validar Y.
- [ ] Verificar se Z está no escopo do MVP ou Fase 2.
