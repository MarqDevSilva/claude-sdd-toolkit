# kotlin-coroutines

> Padrões avançados de coroutines: concorrência estruturada, operadores de Flow e teste de async.

Expert para operações assíncronas complexas. Cobre concorrência estruturada (`supervisorScope`, `coroutineScope`), operadores avançados de Flow (`flatMapLatest`, `combine`, `merge`, `shareIn`, `stateIn`), `channels`/`callbackFlow`, gestão de dispatchers, tratamento de exceções e teste de código assíncrono com `runTest` e Turbine.

## Quando usar

- Concorrência estruturada com `supervisorScope`/`coroutineScope`.
- Operadores avançados de Flow e conversão de cold para hot (`shareIn`/`stateIn`).
- `callbackFlow` para pontes de callbacks e backpressure em streams.
- Testar código async com `runTest` e Turbine.

## Conteúdo

- `SKILL.md` — modelo mental e padrões de async avançado.
- `references/advanced-flow-operators.md` — operadores avançados de Flow.
- `references/relay-patterns.md` — padrões de stream/conexão.
- `references/testing-coroutines.md` — teste de coroutines.

## Relação com outras skills

Expert de baixo nível invocado pela `kmp-architect`; delega `StateFlow`/`SharedFlow` básicos para `kotlin-expert`. As convenções de stack do projeto vêm da `kmp-architect`, que documenta o override da stack Amethyst citada aqui — aplique os padrões de coroutines, não as libs específicas do Amethyst.
