---
app: <app>                 # ex.: portal-fornecedor
persona: <persona>         # ex.: fornecedor (dono de loja / prestador)
status: rascunho           # rascunho | aprovado
versao: 1
gerado-por: ui-blueprint
criado-em: <YYYY-MM-DD>
atualizado-em: <YYYY-MM-DD>
fontes:
  modulos: [.spec/discovery/module_<x>.md, ...]
  domains-index: .spec/discovery/_domain-index.md
---

# Blueprint de UI — `<app>`

> Mapa de telas do app cruzando **módulos × domains**. Artefato pra **revisão humana** antes de
> emitir a fila de specs. Tela = área/jornada que compõe 1..N domains (NUNCA 1 tela por domain).

## 1. Escopo de domains

> Quais domains este app (persona) consome. Derivado dos módulos; paths são desempate.

### Dentro

| Domain | Recurso (baseUrl) | Por que (módulo/RF) |
|--------|-------------------|---------------------|
| `produtos` | `/products` | module_catalogo.md#rf-01 |
| ... | ... | ... |

### Fora (de outra persona)

- `franchise-*` → app franqueado
- `busca-publica`, `carrinho` → app cliente

### Ambíguos (decisão do usuário)

- [ ] `notifications` — usar no fornecedor? (provável: sim, na topbar)
- [ ] ...

## 2. Mapa de áreas → páginas

> Cada página é um vertical slice (lista → detalhe → criar/editar). **1 página = 1 spec.**

### Área: <Nome da área>  (ex.: Catálogo)

| # | Página | Rota | Domains consumidos | Tipo | Prioridade |
|---|--------|------|--------------------|------|------------|
| 1 | Produtos | `/catalogo/produtos` | `produtos` (+ `variantes-de-produto`, `imagens-de-produto`, `horarios-de-produto`, lê `categorias`) | CRUD | P0 |
| 2 | Categorias | `/catalogo/categorias` | `categorias` | CRUD (read p/ fornecedor?) | P1 |

### Área: <Outra área>

| # | Página | Rota | Domains consumidos | Tipo | Prioridade |
|---|--------|------|--------------------|------|------------|
| ... | ... | ... | ... | ... | ... |

> **Tipo**: CRUD | lista/relatório | detalhe | form | dashboard | perfil | wizard.
> **Prioridade**: P0 (MVP) | P1 | P2 — vem do roadmap dos módulos.

## 3. Árvore de navegação (sidebar)

```
<app>
├── Home / Dashboard            (/)
├── Catálogo
│   ├── Produtos                (/catalogo/produtos)
│   └── Categorias              (/catalogo/categorias)
├── Pedidos
│   └── ...
├── Financeiro
│   └── ...
└── Configurações
    └── ...
```

## 4. Shell / layout

- **Layout app (autenticado)**: sidebar colapsável + topbar + `router-outlet`.
  - Topbar: <contexto da persona — ex.: seletor de loja, sino de notificações (`notifications`), menu do usuário (`autenticacao`)>.
- **Layout auth (público)**: login / recuperar senha / verificar email (`autenticacao`) — fora do shell.
- **UI lib / tema**: <a definida no README do front>.
- **Guards**: `authGuard` nas rotas do shell.

## 5. Sequência de construção sugerida

> Ordem de drain (vertical slices por valor). O usuário ajusta.

1. (prereq) Shell + UI lib + auth layout + rotas stub.
2. UI-001 — <página P0>
3. UI-002 — <página P0>
4. ...

## 6. Pontos em aberto

- [ ] Domains ambíguos da seção 1.
- [ ] Páginas que dependem de RFs ainda marcados "Fase 2" nos módulos.
- [ ] ...
