# kotlin-multiplatform

> Decisões de abstração de plataforma em KMP: compartilhar vs manter platform-specific.

Expert que guia onde cada pedaço de código deve viver num projeto KMP — `commonMain`, source sets específicos ou `expect/actual`. Cobre a árvore de decisão de abstração, posicionamento em source sets, criação de `expect/actual` e detecção de código no módulo errado.

## Quando usar

- "Devo criar `expect/actual` ou manter só em uma plataforma?"
- "Posso compartilhar essa lógica de ViewModel/parsing?"
- Dúvidas de posicionamento em source set (`commonMain`, etc.).
- Detectar código colocado no módulo errado.

## Conteúdo

- `SKILL.md` — árvore de decisão de abstração e padrões de source set.
- `references/abstraction-examples.md` — exemplos de o que compartilhar.
- `references/expect-actual-catalog.md` — catálogo de `expect/actual`.
- `references/source-set-hierarchy.md` — hierarquia de source sets.
- `references/target-compatibility.md` — compatibilidade entre targets.
- `scripts/suggest-kmp-dependency.sh` — sugere dependência KMP.
- `scripts/validate-kmp-structure.sh` — valida a estrutura KMP.

## Relação com outras skills

Expert de baixo nível invocado pela `kmp-architect`. As convenções de stack do projeto (Ktor + kotlinx.serialization + SQLDelight + Koin, alvos Android + iOS, sem Desktop) vêm da `kmp-architect`, que documenta o override da stack Amethyst citada aqui (jvmAndroid, secp256k1). Use os padrões, não as libs específicas do Amethyst.
