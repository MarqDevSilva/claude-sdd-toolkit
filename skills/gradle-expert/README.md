# gradle-expert

> Otimização de build, resolução de dependências e troubleshooting de KMP multi-módulo.

Expert do sistema de build Gradle para projetos KMP. Cobre `build.gradle.kts`/`settings.gradle`, version catalog (`libs.versions.toml`), erros de build e conflitos de dependência, dependências entre módulos e source sets, packaging, performance de build e problemas comuns de KMP + Android Gradle.

## Quando usar

- Editar `build.gradle.kts`, `settings.gradle` ou `libs.versions.toml`.
- Resolver erros de build e conflitos de dependência.
- Configurar dependências entre módulos e source sets.
- Otimizar performance de build ou configurar Proguard/R8.

## Conteúdo

- `SKILL.md` — modelo mental do build e troubleshooting.
- `references/build-commands.md` — comandos de build.
- `references/common-errors.md` — erros comuns e correções.
- `references/dependency-graph.md` — grafo de dependências entre módulos.
- `references/version-catalog-guide.md` — guia do version catalog.
- `scripts/analyze-build-time.sh` — analisa tempo de build.
- `scripts/fix-dependency-conflicts.sh` — ajuda a resolver conflitos.

## Relação com outras skills

Expert de baixo nível invocado pela `kmp-architect`. As convenções de stack do projeto (Ktor + kotlinx.serialization + SQLDelight + Koin, alvos Android + iOS) vêm da `kmp-architect`, que documenta o override da stack Amethyst citada aqui (OkHttp, jvmAndroid, secp256k1, Desktop/JVM) — aplique os padrões de build, não as libs específicas do Amethyst.
