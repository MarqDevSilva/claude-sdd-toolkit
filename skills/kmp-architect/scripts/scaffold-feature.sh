#!/usr/bin/env bash
# scaffold-feature.sh — gera o esqueleto data/domain/presentation de uma feature KMP
# seguindo as convenções da skill kmp-architect.
#
# Uso:
#   ./scaffold-feature.sh <feature> [--pkg com.empresa.app] [--screen Login] \
#                         [--base shared/src/commonMain/kotlin] [--dry-run]
#
# Exemplos:
#   ./scaffold-feature.sh auth --pkg com.empresa.app --screen Login
#   ./scaffold-feature.sh notes --pkg com.empresa.app --screen Notes --dry-run
#
# Cria, em <base>/<pkg-como-path>/<feature>/:
#   data/{remote/dto,local,mapper,repository}
#   domain/{model,repository,usecase}
#   presentation/<screen>/  (UiState, Event, Effect, ViewModel)
# Não sobrescreve arquivos existentes.

set -euo pipefail

FEATURE="${1:-}"
if [[ -z "$FEATURE" || "$FEATURE" == "--help" || "$FEATURE" == "-h" ]]; then
  grep -E '^#( |$)' "$0" | sed 's/^# \{0,1\}//'
  exit 0
fi
shift || true

PKG="com.empresa.app"
SCREEN=""
BASE="shared/src/commonMain/kotlin"
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --pkg) PKG="$2"; shift 2 ;;
    --screen) SCREEN="$2"; shift 2 ;;
    --base) BASE="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    *) echo "Opção desconhecida: $1" >&2; exit 1 ;;
  esac
done

# Capitaliza primeira letra (PascalCase simples)
cap() { printf '%s' "$(printf '%s' "$1" | cut -c1 | tr '[:lower:]' '[:upper:]')$(printf '%s' "$1" | cut -c2-)"; }

FEATURE_PASCAL="$(cap "$FEATURE")"
[[ -z "$SCREEN" ]] && SCREEN="$FEATURE_PASCAL"
SCREEN_PASCAL="$(cap "$SCREEN")"
SCREEN_LOWER="$(printf '%s' "$SCREEN_PASCAL" | tr '[:upper:]' '[:lower:]')"

PKG_PATH="${PKG//.//}"
ROOT="${BASE}/${PKG_PATH}/${FEATURE}"
FPKG="${PKG}.${FEATURE}"   # pacote base da feature

DIRS=(
  "$ROOT/data/remote/dto"
  "$ROOT/data/local"
  "$ROOT/data/mapper"
  "$ROOT/data/repository"
  "$ROOT/domain/model"
  "$ROOT/domain/repository"
  "$ROOT/domain/usecase"
  "$ROOT/presentation/${SCREEN_LOWER}"
)

write_file() {
  local path="$1"; shift
  local content="$1"
  if [[ -f "$path" ]]; then
    echo "  skip (existe): $path"
    return
  fi
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "  [dry-run] criaria: $path"
  else
    printf '%s\n' "$content" > "$path"
    echo "  criado: $path"
  fi
}

echo "Feature '$FEATURE' (pkg=$FPKG, screen=$SCREEN_PASCAL) em $ROOT"
echo "Diretórios:"
for d in "${DIRS[@]}"; do
  if [[ "$DRY_RUN" -eq 1 ]]; then echo "  [dry-run] mkdir -p $d"; else mkdir -p "$d"; fi
done

echo "Arquivos:"

write_file "$ROOT/domain/model/${FEATURE_PASCAL}.kt" \
"package ${FPKG}.domain.model

data class ${FEATURE_PASCAL}(
    val id: String,
)"

write_file "$ROOT/domain/repository/${FEATURE_PASCAL}Repository.kt" \
"package ${FPKG}.domain.repository

import ${FPKG}.domain.model.${FEATURE_PASCAL}

interface ${FEATURE_PASCAL}Repository {
    // TODO: definir o contrato (retorne NetworkResult<...> / Flow<...>)
}"

write_file "$ROOT/domain/usecase/Get${FEATURE_PASCAL}UseCase.kt" \
"package ${FPKG}.domain.usecase

import ${FPKG}.domain.repository.${FEATURE_PASCAL}Repository

class Get${FEATURE_PASCAL}UseCase(
    private val repository: ${FEATURE_PASCAL}Repository,
) {
    // suspend operator fun invoke(...) = repository...
}"

write_file "$ROOT/data/repository/${FEATURE_PASCAL}RepositoryImpl.kt" \
"package ${FPKG}.data.repository

import ${FPKG}.domain.repository.${FEATURE_PASCAL}Repository

class ${FEATURE_PASCAL}RepositoryImpl(
    // private val api: ${FEATURE_PASCAL}Api,
    // private val local: ${FEATURE_PASCAL}LocalDataSource,
) : ${FEATURE_PASCAL}Repository {
    // override ... use safeApiCall { } e mappers
}"

write_file "$ROOT/data/remote/${FEATURE_PASCAL}Api.kt" \
"package ${FPKG}.data.remote

import io.ktor.client.HttpClient

class ${FEATURE_PASCAL}Api(
    private val client: HttpClient,
) {
    // suspend fun ... = client.get(...) / post(...)
}"

write_file "$ROOT/data/local/${FEATURE_PASCAL}LocalDataSource.kt" \
"package ${FPKG}.data.local

class ${FEATURE_PASCAL}LocalDataSource(
    // private val db: AppDatabase,
) {
    // queries SQLDelight da feature
}"

write_file "$ROOT/data/mapper/${FEATURE_PASCAL}Mapper.kt" \
"package ${FPKG}.data.mapper

// fun ${FEATURE_PASCAL}Dto.toDomain() = ...
// fun ${FEATURE_PASCAL}.toEntity() = ...
// fun ${FEATURE_PASCAL}Entity.toDomain() = ..."

write_file "$ROOT/presentation/${SCREEN_LOWER}/${SCREEN_PASCAL}UiState.kt" \
"package ${FPKG}.presentation.${SCREEN_LOWER}

data class ${SCREEN_PASCAL}UiState(
    val isLoading: Boolean = false,
    val error: String? = null,
)"

write_file "$ROOT/presentation/${SCREEN_LOWER}/${SCREEN_PASCAL}Event.kt" \
"package ${FPKG}.presentation.${SCREEN_LOWER}

sealed interface ${SCREEN_PASCAL}Event {
    data object Load : ${SCREEN_PASCAL}Event
}"

write_file "$ROOT/presentation/${SCREEN_LOWER}/${SCREEN_PASCAL}Effect.kt" \
"package ${FPKG}.presentation.${SCREEN_LOWER}

sealed interface ${SCREEN_PASCAL}Effect {
    data class ShowError(val message: String) : ${SCREEN_PASCAL}Effect
}"

write_file "$ROOT/presentation/${SCREEN_LOWER}/${SCREEN_PASCAL}ViewModel.kt" \
"package ${FPKG}.presentation.${SCREEN_LOWER}

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.flow.update

class ${SCREEN_PASCAL}ViewModel(
    // private val get${FEATURE_PASCAL}: Get${FEATURE_PASCAL}UseCase,
) : ViewModel() {
    private val _state = MutableStateFlow(${SCREEN_PASCAL}UiState())
    val state: StateFlow<${SCREEN_PASCAL}UiState> = _state.asStateFlow()

    private val _effect = Channel<${SCREEN_PASCAL}Effect>(Channel.BUFFERED)
    val effect = _effect.receiveAsFlow()

    fun onEvent(event: ${SCREEN_PASCAL}Event) {
        when (event) {
            ${SCREEN_PASCAL}Event.Load -> { /* TODO */ }
        }
    }
}"

echo "Pronto. Lembre de registrar a feature no módulo Koin (core/di/) — ver references/koin-di.md."
