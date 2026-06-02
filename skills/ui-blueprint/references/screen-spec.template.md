---
id: UI-<NNN>
titulo: <Página> — <app>
status: aprovada            # rascunho | em-revisao | aprovada | em-execucao | concluida | arquivada
tipo: ui-screen
app: <app>                  # ex.: portal-fornecedor
area: <area>               # ex.: Catálogo
rota: <rota>               # ex.: /catalogo/produtos
dominios: [<dominio>, ...] # domains consumidos por esta página
gerada-por: ui-blueprint
autor: ui-blueprint
criada-em: <YYYY-MM-DD>
atualizada-em: <YYYY-MM-DD>
relacionadas: [.spec/discovery/<app>-blueprint.md]
---

# UI-<NNN>: <Página> (`<rota>`)

> Spec de **uma página**, auto-gerada do blueprint. Construir conforme `angular-engineer`
> (page smart injeta `state`+`service`; tabelas/forms dumb em `shared/ui`; UI lib do projeto).
> Revisar antes de executar — ajustar UX/regras que não saem do contrato.

## 1. Problema

> Quem usa esta tela e pra quê (1 parágrafo, da perspectiva da persona — RF do módulo).

## 2. Objetivo

> Resultado da página numa frase.

## 3. Escopo

### Dentro
- <ex.: listar, filtrar, criar, editar, excluir <recurso>>

### Fora (não-objetivos)
- <ex.: relatórios avançados, ações em lote — outra spec>

## 4. Contrato de UI

> Inferido dos domains. É a ponte com `angular-engineer`.

### Domains e fonte de dados
| Domain | State (signals) | Service (métodos usados) |
|--------|-----------------|--------------------------|
| `<dominio>` | `itens`, `selecionado`, `carregando`, `erro` | `listar`, `buscarPorId`, `criar`, `atualizar`, `excluir` |

### Layout da página
- **Lista**: tabela de `<TipoResponse>` — colunas: `<campo (label)>`, ... (enums→tag; data→formatada).
- **Detalhe**: <campos exibidos>.
- **Form (criar/editar)**: campos de `<TipoRequest>` — obrigatórios: `<...>`; selects (enum): `<...>`; opcionais: `<...>`.
- **Ações**: <Novo / Editar / Excluir (confirm) / ...> → método do service correspondente.
- **Estados**: `carregando`→skeleton; `erro`→toast/inline (ProblemDetails); vazio→empty-state.

### Componentes
- **Smart (app)**: `<area>/<recurso>.page.ts` (+ detalhe/form pages ou dialogs).
- **Dumb (shared/ui)**: <reusar/criar: data-table, page-header, form-field, confirm-dialog, ...>.

## 5. Critérios de aceitação

1. [ ] Rota `<rota>` registrada no app, dentro do shell, protegida por `authGuard`.
2. [ ] Lista carrega via `<dominio>.service.<listar>()` e exibe os itens; estados de loading/vazio/erro cobertos.
3. [ ] Criar/editar persiste via `criar`/`atualizar`; validação reflete os `required` do `*Request`.
4. [ ] Excluir confirma e chama `excluir`; lista atualiza.
5. [ ] `ng build <app>` e `ng test` verdes; a página renderiza no browser.

## 6. Requisitos não-funcionais

| NFR | Alvo | Como medir |
|-----|------|------------|
| Acessibilidade | navegável por teclado, labels nos campos | revisão manual |
| Performance | lista renderiza < 1s com dados mock | observação |
| Erro | toda falha → ProblemDetails no `state.erro`, sem tela quebrada | teste de erro |

## 7. Riscos e premissas

| Item | Tipo | Mitigação |
|------|------|-----------|
| <ex.: endpoint paginado (Pageable)> | premissa | usar params page/size do service |

## 8. Perguntas em aberto

- [ ] <decisão de UX não derivável do contrato>

## 9. Verificação (antes de arquivar)

- [ ] Rota acessível e dentro do shell.
- [ ] CRUD funcionando contra o(s) domain(s) (teste/observação).
- [ ] Sem import de `environment`/`HttpClient` fora do service; page só lê `state` e chama `service`.
- [ ] Build + testes verdes.
