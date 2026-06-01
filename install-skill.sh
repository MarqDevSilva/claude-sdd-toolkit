#!/usr/bin/env bash
#
# install-skill.sh — instala UMA pasta (skill) de um repositório público do GitHub,
# sem clonar o projeto inteiro. Usa `npx degit` por baixo.
#
# Uso:
#   ./install-skill.sh <url-da-pasta-no-github> [destino] [--force]
#
# Exemplos:
#   ./install-skill.sh https://github.com/Jeffallan/claude-skills/tree/main/skills/spring-boot-engineer
#   ./install-skill.sh https://github.com/Jeffallan/claude-skills/tree/main/skills/spring-boot-engineer skills
#   ./install-skill.sh Jeffallan/claude-skills/skills/spring-boot-engineer#main   # atalho estilo degit
#
# Por padrão instala em skills/<nome-da-skill>.
# Requer: bash, npx (Node.js).

set -euo pipefail

# ---- cores (degradam pra vazio se não for TTY) ------------------------------
if [[ -t 1 ]]; then
  BOLD=$'\033[1m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m'; DIM=$'\033[2m'; RESET=$'\033[0m'
else
  BOLD=""; GREEN=""; YELLOW=""; RED=""; DIM=""; RESET=""
fi

die() { echo "${RED}✗ $*${RESET}" >&2; exit 1; }

usage() {
  cat >&2 <<EOF
${BOLD}install-skill.sh${RESET} — instala uma pasta (skill) de um repo público do GitHub.

Uso:
  ./install-skill.sh <url-github> [destino] [--force]

Argumentos:
  <url-github>   URL da pasta (ex.: https://github.com/owner/repo/tree/main/path/to/skill)
                 ou atalho degit (owner/repo/path#ref)
  [destino]      Pasta-pai onde instalar (padrão: skills)
  --force        Sobrescreve se o destino já existir

Exemplos:
  ./install-skill.sh https://github.com/Jeffallan/claude-skills/tree/main/skills/spring-boot-engineer
EOF
  exit 1
}

# ---- parse args -------------------------------------------------------------
SRC=""
DEST_PARENT="skills"
FORCE=0

for arg in "$@"; do
  case "$arg" in
    -h|--help) usage ;;
    --force)   FORCE=1 ;;
    -*)        die "Flag desconhecida: $arg" ;;
    *)
      if [[ -z "$SRC" ]]; then SRC="$arg"
      else DEST_PARENT="$arg"
      fi
      ;;
  esac
done

[[ -n "$SRC" ]] || usage
command -v npx >/dev/null 2>&1 || die "npx (Node.js) não encontrado. Instale o Node: https://nodejs.org"

# ---- normaliza a fonte para o formato do degit: owner/repo/path#ref ---------
# Aceita:
#   1) URL web do GitHub:  https://github.com/OWNER/REPO/tree/REF/PATH...
#   2) Atalho degit:       OWNER/REPO/PATH#REF  (passa direto)
REF="main"
if [[ "$SRC" == http*://* || "$SRC" == github.com/* ]]; then
  # tira protocolo e host
  path="${SRC#http://}"; path="${path#https://}"; path="${path#github.com/}"
  # path agora: OWNER/REPO/tree/REF/PATH...
  IFS='/' read -r OWNER REPO KEYWORD REF REST <<< "$path"
  [[ -n "${OWNER:-}" && -n "${REPO:-}" ]] || die "URL inválida: não consegui extrair owner/repo de '$SRC'"
  if [[ "${KEYWORD:-}" == "tree" || "${KEYWORD:-}" == "blob" ]]; then
    SUBPATH="$REST"
  else
    # sem /tree/REF/ — assume que tudo após o repo é o subpath, ref=main
    SUBPATH="${KEYWORD:+$KEYWORD/}${REF:+$REF/}${REST}"
    SUBPATH="${SUBPATH%/}"
    REF="main"
  fi
  [[ -n "${SUBPATH:-}" ]] || die "A URL precisa apontar para uma PASTA dentro do repo, não a raiz."
  DEGIT_SRC="${OWNER}/${REPO}/${SUBPATH}#${REF}"
  SKILL_NAME="$(basename "$SUBPATH")"
else
  # atalho degit direto: OWNER/REPO/PATH#REF
  DEGIT_SRC="$SRC"
  base="${SRC%%#*}"
  [[ "$SRC" == *#* ]] && REF="${SRC##*#}"
  IFS='/' read -r OWNER REPO _REST <<< "$base"
  SUBPATH="$_REST"
  [[ -n "${OWNER:-}" && -n "${REPO:-}" && -n "${SUBPATH:-}" ]] \
    || die "Atalho inválido. Use OWNER/REPO/PATH#REF (ex.: angular/angular/skills/dev-skills/angular-developer#main)"
  SKILL_NAME="$(basename "$base")"
fi

# ---- fallback: baixa só a subpasta via git sparse-checkout ------------------
# Usado quando o degit falha (ex.: monorepos gigantes como angular/angular, onde
# o `git ls-remote` retorna ~45k refs e estoura o maxBuffer interno do degit).
sparse_fetch() {
  command -v git >/dev/null 2>&1 || die "git não encontrado para o fallback de sparse-checkout."
  local tmp; tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN
  echo "${DIM}  (sparse-checkout: $OWNER/$REPO@$REF → $SUBPATH)${RESET}"
  git clone --filter=blob:none --no-checkout --depth 1 --branch "$REF" \
      "https://github.com/${OWNER}/${REPO}.git" "$tmp/repo" >/dev/null 2>&1 \
    || die "git clone falhou. Verifique owner/repo/ref e se o repo é público."
  ( cd "$tmp/repo" \
      && git sparse-checkout set --no-cone "$SUBPATH" >/dev/null 2>&1 \
      && git checkout >/dev/null 2>&1 ) \
    || die "sparse-checkout falhou para '$SUBPATH'."
  [[ -d "$tmp/repo/$SUBPATH" ]] || die "Pasta '$SUBPATH' não encontrada no repo após checkout."
  rm -rf "$DEST"
  mkdir -p "$(dirname "$DEST")"
  mv "$tmp/repo/$SUBPATH" "$DEST"
}

DEST="${DEST_PARENT%/}/${SKILL_NAME}"

echo "${DIM}Fonte:${RESET}  $DEGIT_SRC"
echo "${DIM}Destino:${RESET} $DEST"
echo

# ---- destino já existe? -----------------------------------------------------
if [[ -e "$DEST" ]]; then
  if [[ "$FORCE" -eq 1 ]]; then
    echo "${YELLOW}⚠ $DEST já existe — sobrescrevendo (--force).${RESET}"
  else
    die "$DEST já existe. Use --force para sobrescrever."
  fi
fi

mkdir -p "$DEST_PARENT"

# ---- baixa só a pasta -------------------------------------------------------
echo "${BOLD}↓ Baixando skill...${RESET}"
DEGIT_FLAGS=()
[[ "$FORCE" -eq 1 ]] && DEGIT_FLAGS+=(--force)
if ! npx --yes degit ${DEGIT_FLAGS[@]+"${DEGIT_FLAGS[@]}"} "$DEGIT_SRC" "$DEST" 2>/dev/null; then
  echo "${YELLOW}! degit falhou (repo grande demais?) — tentando via git sparse-checkout...${RESET}"
  sparse_fetch
fi

# ---- valida que parece uma skill -------------------------------------------
if [[ -f "$DEST/SKILL.md" ]]; then
  echo "${GREEN}✓ Skill instalada em $DEST${RESET}"
else
  echo "${YELLOW}⚠ Instalado em $DEST, mas sem SKILL.md na raiz — confira se é mesmo uma skill.${RESET}"
fi

echo
echo "${DIM}Conteúdo:${RESET}"
ls -1 "$DEST"
