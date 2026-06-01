# project-onboard

> Faz engenharia reversa leve de um projeto que JÁ EXISTE e grava a memória de arquitetura/convenções.

Par do `app-kickoff`, mas para projetos brownfield. Em vez de descobrir do zero, lê o código de forma cirúrgica (manifestos + uma feature de referência apontada pelo usuário) para mapear stack, arquitetura e convenções, gravando o resultado em `.spec/memory/` para specs futuras seguirem o que já existe.

## Quando usar

- Comando explícito `/project-onboard`.
- Usuário quer adotar SDD num projeto que já tem código.
- Pedido para "mapear a arquitetura", "entender o codebase" ou "documentar como o projeto funciona".
- Antes de abrir a primeira SPEC de refatoração/feature num projeto legado.

## Conteúdo

- `SKILL.md` — processo em 4 fases (escopo, stack/topologia, rastreio da feature, convenções) com o princípio de não varrer o repo inteiro.
- `references/architecture.template.md` — estrutura do `architecture.md` (stack, topologia, padrão arquitetural, fluxo).
- `references/conventions.template.md` — estrutura do `conventions.md` (nomenclatura, pastas, testes, anti-padrões).

## Relação com outras skills

Ponto de entrada do fluxo SDD para projetos existentes (alternativa a `app-kickoff`). A memória gravada aqui é consultada por `spec-new`, `spec-plan` e `spec-review` para manter coerência: project-onboard → spec-new → spec-review → spec-plan → spec-tasks → implementação.
