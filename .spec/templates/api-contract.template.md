---
spec: SPEC-<NNN>
versao-api: v1
status: rascunho   # rascunho | acordado | implementado
---

# Contrato de API — <Recurso>

> Fonte da verdade do contrato entre Spring (provider) e Angular (consumer).
> Idealmente gerado por springdoc-openapi. Este arquivo serve como **espelho legível** + acordo.

## Recurso: `<NomeRecurso>`

### Endpoints

| Método | Path | Descrição | Auth |
|--------|------|-----------|------|
| GET | `/api/v1/<recurso>` | Lista paginada | Sim |
| GET | `/api/v1/<recurso>/{id}` | Detalhe | Sim |
| POST | `/api/v1/<recurso>` | Cria | Sim |
| PUT | `/api/v1/<recurso>/{id}` | Substitui | Sim |
| PATCH | `/api/v1/<recurso>/{id}` | Atualiza parcial | Sim |
| DELETE | `/api/v1/<recurso>/{id}` | Remove | Sim |

### Schemas

#### `<Recurso>Request`

```json
{
  "campo1": "string (obrigatório, 1-255)",
  "campo2": "number (opcional, ≥ 0)"
}
```

#### `<Recurso>Response`

```json
{
  "id": "uuid",
  "campo1": "string",
  "campo2": "number | null",
  "criadoEm": "ISO-8601",
  "atualizadoEm": "ISO-8601"
}
```

#### `PageResponse<T>`

```json
{
  "content": "T[]",
  "page": "number (0-indexed)",
  "size": "number",
  "totalElements": "number",
  "totalPages": "number"
}
```

### Códigos de erro específicos

| Status | Código de domínio | Quando |
|--------|-------------------|--------|
| 422 | `RECURSO_DUPLICADO` | Já existe recurso com mesma chave única |
| 422 | `RECURSO_INVALIDO` | Falha de regra de domínio |
| 404 | `RECURSO_NAO_ENCONTRADO` | ID inexistente |

Formato do payload de erro: [RFC 7807 `ProblemDetail`](https://www.rfc-editor.org/rfc/rfc7807).

```json
{
  "type": "https://app.example/errors/recurso-duplicado",
  "title": "Recurso duplicado",
  "status": 422,
  "detail": "Já existe recurso com X = Y",
  "instance": "/api/v1/recurso",
  "codigo": "RECURSO_DUPLICADO"
}
```

### Idempotência

- Operações `GET`, `PUT`, `DELETE` são idempotentes por design.
- `POST` aceita header `Idempotency-Key` (UUID) quando aplicável.

### Paginação, ordenação e filtros

- Query params: `?page=0&size=20&sort=campo,asc&filtro=valor`.
- Defaults: `page=0`, `size=20`, sem ordenação implícita (definir por endpoint quando necessário).

## Checklist de sincronização

- [ ] OpenAPI gerado pelo Spring atualizado
- [ ] Cliente TS regenerado (openapi-generator)
- [ ] Tipos do front consumidos a partir do client gerado, **não** redeclarados
- [ ] Testes de contrato (se aplicável) atualizados
