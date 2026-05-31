---
status: rascunho   # rascunho | validado
versao: 1
criado-em: <YYYY-MM-DD>
atualizado-em: <YYYY-MM-DD>
fonte: project-onboard   # convenções observadas no código existente
---

# Convenções — Nome do Projeto

> Gerado por [`/project-onboard`](../SKILL.md) a partir do código existente.
> São convenções **observadas** (repetidas em ≥2 lugares), não regras inventadas. Consumido por `/spec-plan`/`/spec-review`.
> Separe **padrão a seguir** de **dívida a não replicar**.

## 1. Nomenclatura

| Elemento | Padrão observado | Exemplo |
|----------|------------------|---------|
| Arquivos | ... | `cliente.service.ts` |
| Classes / tipos | ... | `ClienteController` |
| Pastas | ... | `features/clientes/` |
| Endpoints | ... | `/api/v1/clientes` |

## 2. Estrutura de pastas por camada

> Como uma unidade de código (feature/módulo) se organiza internamente.

```
feature/
├── ...
└── ...
```

## 3. Padrões de teste

- **Onde ficam**: ...
- **Tipos usados**: unit / slice / integração / e2e — ...
- **Naming**: ...
- **Ferramentas**: ...

## 4. Tratamento de erros

- **Backend**: ... (ex: `@RestControllerAdvice` global, `ProblemDetail`/RFC 7807, códigos de domínio)
- **Frontend**: ... (ex: interceptor HTTP, store de erro, toasts)

## 5. Contrato de API

- **Versionamento**: ... (ex: `/api/v1`)
- **Formato de erro**: ...
- **Paginação/filtros**: ...
- **Cliente TS gerado?** sim/não — como.

## 6. Estado e fluxo de dados (frontend)

- **Gerência de estado**: signals / store / facade / serviço — ...
- **Padrão de comunicação com API**: ...

## 7. Padrão a seguir × dívida a não replicar

| Observado | Veredito | Nota |
|-----------|----------|------|
| ... | ✅ seguir | ... |
| ... | ⚠️ dívida — não replicar | ... |

## 8. Inferências a confirmar

- [ ] 🔎 ...
