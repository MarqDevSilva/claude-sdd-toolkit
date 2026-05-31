# Glossário do Domínio

> Termos do negócio + termos técnicos do projeto. Mantenha aqui para evitar ambiguidade em specs.
> Esta é uma tabela template — substitua os exemplos pelos termos reais do seu projeto.

## Termos de negócio

| Termo | Definição | Notas |
|-------|-----------|-------|
| _Cliente_ | Pessoa ou empresa que consome o serviço | Distinto de _Usuário_ (que faz login no sistema) |
| _Usuário_ | Conta autenticável no sistema | Um cliente pode ter N usuários |
| _Pedido_ | Solicitação registrada de produto ou serviço | Estados: rascunho, confirmado, cancelado, finalizado |

## Termos técnicos do projeto

| Termo | Definição |
|-------|-----------|
| _Spec_ | Documento em `.spec/changes/` ou `.spec/archive/` descrevendo uma mudança |
| _Plan_ | Plano técnico derivado de uma spec, vive ao lado dela |
| _ADR_ | Architecture Decision Record — decisão arquitetural com contexto, opções e consequências |
| _NFR_ | Non-Functional Requirement — performance, segurança, observabilidade, etc. |

## Convenções de uso

- Use o termo **exatamente** como está aqui em specs e código (case-sensitive nos identificadores).
- Termo não está no glossário? Adicione antes de usar.
- Sinônimos são proibidos: escolha um termo e bane os outros.
