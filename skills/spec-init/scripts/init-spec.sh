#!/usr/bin/env bash
# init-spec.sh — cria a estrutura .spec/ completa do fluxo SDD em um projeto
# que ainda não a tem. Idempotente: nunca apaga nada, só completa o que falta.
#
# Uso:
#   ./init-spec.sh [destino] [--force] [--no-readme] [--dry-run]
#
# Exemplos:
#   ./init-spec.sh                       # cria .spec/ no diretório atual
#   ./init-spec.sh /caminho/do/projeto   # cria .spec/ na raiz desse projeto
#   ./init-spec.sh --dry-run             # mostra o que faria, sem escrever
#   ./init-spec.sh --force               # reescreve o .spec/README.md se já existir
#   ./init-spec.sh --no-readme           # só cria as pastas + .gitkeep, sem README
#
# Cria, em <destino>/.spec/:
#   discovery/   changes/   archive/   memory/   templates/
# Cada pasta recebe um .gitkeep (pra versionar a pasta vazia no git) e a raiz
# recebe um README.md explicando o propósito de cada uma (a menos que --no-readme).
# Pastas e arquivos que já existem são preservados (skip), nunca sobrescritos —
# exceto o README.md quando --force é passado.

set -euo pipefail

DEST="."
FORCE=0
NO_README=0
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) awk 'NR>1 && /^#( |$)/ {sub(/^# ?/,""); print; next} NR>1 {exit}' "$0"; exit 0 ;;
    --force) FORCE=1; shift ;;
    --no-readme) NO_README=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -*) echo "Opção desconhecida: $1" >&2; exit 1 ;;
    *) DEST="$1"; shift ;;
  esac
done

if [[ ! -d "$DEST" ]]; then
  echo "Destino não existe ou não é um diretório: $DEST" >&2
  exit 1
fi

SPEC="${DEST%/}/.spec"

SUBDIRS=(discovery changes archive memory templates)

run() {
  # run "<mensagem>" <comando...>
  local msg="$1"; shift
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "  [dry-run] $msg"
  else
    "$@"
    echo "  $msg"
  fi
}

if [[ -d "$SPEC" ]]; then
  echo ".spec/ já existe em $DEST — completando o que estiver faltando."
else
  echo "Criando estrutura .spec/ em $DEST"
fi

# Pasta raiz .spec/
[[ -d "$SPEC" ]] || run "criado: $SPEC/" mkdir -p "$SPEC"

# Subpastas + .gitkeep
for d in "${SUBDIRS[@]}"; do
  dir="$SPEC/$d"
  if [[ -d "$dir" ]]; then
    echo "  skip (existe): $dir/"
  else
    run "criado: $dir/" mkdir -p "$dir"
  fi
  keep="$dir/.gitkeep"
  if [[ -f "$keep" ]]; then
    echo "  skip (existe): $keep"
  else
    run "criado: $keep" touch "$keep"
  fi
done

# README.md da raiz .spec/
README="$SPEC/README.md"
write_readme() {
  cat > "$README" <<'EOF'
# .spec/ — diretório de trabalho do fluxo SDD

Spec-Driven Development. Cada pasta tem um papel no ciclo de vida de uma feature.

| Pasta         | Para quê                                                                 |
|---------------|--------------------------------------------------------------------------|
| `discovery/`  | Saída do `/app-kickoff` (projeto novo): `brief.md`, `module_<nome>.md`, `entities.md`, `roadmap.md`. |
| `changes/`    | Specs em andamento, uma pasta por mudança: `SPEC-NNN-slug/` com `spec.md`, depois `plan.md` e `tasks.md`. |
| `archive/`    | Specs concluídas — mova `SPEC-NNN-slug/` pra cá quando a feature for mergeada. |
| `memory/`     | Memória do projeto (`/project-onboard`): `architecture.md` + `conventions.md`. Specs futuras consultam isso. |
| `templates/`  | Espaço pra templates próprios do projeto, se você quiser sobrescrever os das skills. |

## Fluxo resumido

```
0a. /app-kickoff     → discovery/ (projeto NOVO)
0b. /project-onboard → memory/    (projeto EXISTENTE)
      ↓
1. /spec-new   → changes/SPEC-NNN-slug/spec.md
2. /spec-review
3. /spec-plan  → plan.md
4. /spec-tasks → tasks.md
5. <implementar>
6. feature mergeada → mover SPEC-NNN-slug/ para archive/
```
EOF
}

if [[ "$NO_README" -eq 1 ]]; then
  echo "  skip (--no-readme): $README"
elif [[ -f "$README" && "$FORCE" -eq 0 ]]; then
  echo "  skip (existe, use --force pra reescrever): $README"
else
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "  [dry-run] criaria: $README"
  else
    write_readme
    echo "  criado: $README"
  fi
fi

echo "Pronto. Próximo passo: /app-kickoff (projeto novo) ou /project-onboard (projeto existente)."
