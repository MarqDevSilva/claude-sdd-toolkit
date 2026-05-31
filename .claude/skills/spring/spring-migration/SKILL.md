---
name: spring-migration
description: Gera migration Flyway forward-only a partir de uma entity JPA ou de uma mudança de schema descrita, com nomenclatura e índices padronizados.
---

# spring-migration

Use quando o usuário pedir pra **criar migration**, **gerar SQL de schema**, **adicionar coluna/tabela**, **alterar schema** em projeto Spring com Flyway.

## Pré-requisitos

- Projeto usa Flyway (verificar `src/main/resources/db/migration/`).
- Banco-alvo (default: Postgres). Se outro, perguntar.

## O que faz

1. Pergunta:
   - É tabela nova, alteração ou seed?
   - Se vier de entity: caminho do arquivo `.java`.
   - Se for alteração: descrição da mudança.
2. Gera nome do arquivo: `V<timestamp>__<descricao_snake_case>.sql`.
   - `<timestamp>` = `YYYYMMDDHHmm` (use o relógio do sistema).
3. Cria SQL forward-only no diretório `src/main/resources/db/migration/`.

## Convenções de SQL

### Tabela

```sql
CREATE TABLE invoice (
    id          UUID PRIMARY KEY,
    valor       NUMERIC(12,2) NOT NULL,
    status      VARCHAR(20) NOT NULL,
    criado_em   TIMESTAMPTZ NOT NULL DEFAULT now(),
    atualizado_em TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT invoice_valor_positivo CHECK (valor > 0)
);

CREATE INDEX idx_invoice_status ON invoice (status);
```

### Adicionar coluna

```sql
-- adiciona coluna como NULL inicialmente
ALTER TABLE invoice ADD COLUMN cliente_id UUID;

-- backfill
UPDATE invoice SET cliente_id = ... WHERE cliente_id IS NULL;

-- então tornar NOT NULL
ALTER TABLE invoice ALTER COLUMN cliente_id SET NOT NULL;

-- FK no final
ALTER TABLE invoice
    ADD CONSTRAINT fk_invoice_cliente
    FOREIGN KEY (cliente_id) REFERENCES cliente(id);
```

### Padrões de nomenclatura

- Tabelas em **snake_case singular** (`invoice`, não `invoices`).
- Colunas em **snake_case** (`criado_em`).
- Índices: `idx_<tabela>_<colunas>`.
- FKs: `fk_<tabela>_<refTabela>`.
- Constraints unique: `uk_<tabela>_<colunas>`.
- Check: `<tabela>_<descricao>`.

## Regras

- **Forward-only.** Nada de `DROP` destrutivo sem ADR aprovado.
- **Compatível com código antigo durante o deploy.** Se renomear coluna: cria nova, popula, código novo lê nova, code antiga deprecated, próxima migration remove velha.
- **Idempotência onde possível** (`IF NOT EXISTS` em `CREATE INDEX`).
- **Sem dados sensíveis** no script (sem hardcoded de PII).

## Heurísticas

- Sempre que criar FK, **considerar índice** na coluna FK.
- Sempre que adicionar coluna obrigatória em tabela existente: **3 passos** (add nullable → backfill → set not null).
- Verificar se a entity JPA correspondente tem `@Column(name = "...")` quando o nome do campo Java diverge da coluna.

## Como invocar

```
/spring-migration
/spring-migration "adicionar coluna cliente_id em invoice"
/spring-migration src/main/java/com/app/invoice/domain/Invoice.java
```

## Saída

- Caminho do arquivo SQL gerado.
- Lembrete pra rodar `mvn flyway:migrate` (ou Gradle equivalente) em dev pra validar.
- Aviso se a mudança é breaking change (sugerir feature flag + plano de rollout multi-deploy).
