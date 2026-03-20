#!/bin/zsh

slugify() {
  local text="${1:l}"
  text="${text// /-}"
  text="${text//\//-}"
  text="${text//_/-}"
  text=$(printf '%s' "$text" | /usr/bin/tr -cd '[:alnum:]-')
  printf '%s\n' "${text:-tool}"
}

display_path() {
  local path="$1"
  printf '%s\n' "${path/#$HOME/~}"
}

resolve_cmd_path() {
  local cmd="$1"
  local path=""

  path=$(whence -p "$cmd" 2>/dev/null || true)
  [[ -n "$path" && -x "$path" ]] && {
    printf '%s\n' "$path"
    return 0
  }

  path=$(command -v "$cmd" 2>/dev/null || true)
  [[ -n "$path" && "$path" = /* && -x "$path" ]] && printf '%s\n' "$path"
  return 0
}

tool_version_or_unknown() {
  local cmd="$1"

  if ! resolve_cmd_path "$cmd" >/dev/null; then
    printf 'unknown\n'
    return 0
  fi

  (
    "$cmd" --version 2>/dev/null | /usr/bin/head -n 1
  ) || (
    "$cmd" -V 2>/dev/null | /usr/bin/head -n 1
  ) || (
    "$cmd" version 2>/dev/null | /usr/bin/head -n 1
  ) || printf 'installed\n'
}

display_markdown_file() {
  local file="$1"

  if command -v bat >/dev/null 2>&1; then
    bat --paging=never --style=plain "$file"
  else
    cat "$file"
  fi
}

toml_escape() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  printf '%s\n' "$value"
}

parse_toml_string() {
  local raw="$1"
  raw="${raw#\"}"
  raw="${raw%\"}"
  printf '%s\n' "${raw//\\\"/\"}"
}

parse_toml_bool() {
  local raw="$1"
  raw="${raw:l}"
  [[ "$raw" == "true" ]] && printf '1\n' || printf '0\n'
}

read_config_value() {
  local config_file="$1"
  local key="$2"
  [[ -r "$config_file" ]] || return 0

  /usr/bin/awk -F'=' -v key="$key" '
    {
      current = $1
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", current)
    }
    current == key {
      value = $2
      sub(/[[:space:]]+$/, "", value)
      sub(/^[[:space:]]+/, "", value)
      print value
      exit
    }
  ' "$config_file"
  return 0
}

load_tool_help_config() {
  local config_file="$1"
  local raw=""

  TOOL_HELP_CONFIG_DEFAULT_PROVIDER="opencode"
  TOOL_HELP_CONFIG_DEFAULT_MODEL_OPENCODE="openai/gpt-5.4-mini"
  TOOL_HELP_CONFIG_DEFAULT_MODEL_CODEX="gpt-5.4"
  TOOL_HELP_CONFIG_AI_ENABLED=1
  TOOL_HELP_CONFIG_PREFER_TEALDEER=1
  TOOL_HELP_CONFIG_REQUIRE_TEALDEER=0

  raw=$(read_config_value "$config_file" "default_provider" || true)
  [[ -n "$raw" ]] && TOOL_HELP_CONFIG_DEFAULT_PROVIDER=$(parse_toml_string "$raw")

  raw=$(read_config_value "$config_file" "default_model_opencode" || true)
  [[ -n "$raw" ]] && TOOL_HELP_CONFIG_DEFAULT_MODEL_OPENCODE=$(parse_toml_string "$raw")

  raw=$(read_config_value "$config_file" "default_model_codex" || true)
  [[ -n "$raw" ]] && TOOL_HELP_CONFIG_DEFAULT_MODEL_CODEX=$(parse_toml_string "$raw")

  raw=$(read_config_value "$config_file" "ai_enabled_by_default" || true)
  [[ -n "$raw" ]] && TOOL_HELP_CONFIG_AI_ENABLED=$(parse_toml_bool "$raw")

  raw=$(read_config_value "$config_file" "prefer_tealdeer" || true)
  [[ -n "$raw" ]] && TOOL_HELP_CONFIG_PREFER_TEALDEER=$(parse_toml_bool "$raw")

  raw=$(read_config_value "$config_file" "require_tealdeer" || true)
  [[ -n "$raw" ]] && TOOL_HELP_CONFIG_REQUIRE_TEALDEER=$(parse_toml_bool "$raw")
  return 0
}

tool_help_default_model_for_provider() {
  local provider="$1"
  case "$provider" in
    opencode) printf '%s\n' "$TOOL_HELP_CONFIG_DEFAULT_MODEL_OPENCODE" ;;
    codex) printf '%s\n' "$TOOL_HELP_CONFIG_DEFAULT_MODEL_CODEX" ;;
    *) printf '\n' ;;
  esac
}

tool_inventory_context() {
  local tool_name="$1"
  local inventory_file="$2"

  [[ -r "$inventory_file" ]] || return 0

  /usr/bin/awk -F'|' -v tool="$tool_name" '
    index($0, "| `" tool "` |") {
      for (i = 1; i <= NF; i++) {
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", $i)
      }
      print "- Inventory description: " $3
      print "- Why it exists here: " $4
      print "- Reported version: " $5
      print "- Reported path: " $6
      print "- Reported source: " $7
      exit
    }
  ' "$inventory_file"
}

tool_inventory_path() {
  local tool_name="$1"
  local inventory_file="$2"

  [[ -r "$inventory_file" ]] || return 0

  /usr/bin/awk -F'|' -v tool="$tool_name" '
    index($0, "| `" tool "` |") {
      value = $6
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      gsub(/^`|`$/, "", value)
      print value
      exit
    }
  ' "$inventory_file"
}

tool_help_source_file_for() {
  local source_dir="$1"
  local kind="$2"
  printf '%s\n' "$source_dir/$kind.txt"
}

tool_help_has_source() {
  local source_dir="$1"
  local kind="$2"
  [[ -s "$(tool_help_source_file_for "$source_dir" "$kind")" ]]
}

tool_help_capture_command() {
  local target_file="$1"
  shift
  local tmp_file
  tmp_file="$(mktemp "${TMPDIR:-/tmp}/tool-help.capture.XXXXXX")"

  "$@" >"$tmp_file" 2>&1 || true
  if [[ -s "$tmp_file" ]]; then
    mv "$tmp_file" "$target_file"
    return 0
  fi

  rm -f "$tmp_file"
  return 1
}

tool_help_collect_tldr() {
  local tool_name="$1"
  local target_file="$2"

  if command -v tldr >/dev/null 2>&1; then
    tool_help_capture_command "$target_file" tldr "$tool_name"
    return $?
  fi

  if command -v tealdeer >/dev/null 2>&1; then
    tool_help_capture_command "$target_file" tealdeer "$tool_name"
    return $?
  fi

  return 1
}

tool_help_collect_help() {
  local tool_name="$1"
  local target_file="$2"

  resolve_cmd_path "$tool_name" >/dev/null || return 1
  tool_help_capture_command "$target_file" "$tool_name" --help
}

tool_help_collect_man() {
  setopt localoptions no_pipefail
  local tool_name="$1"
  local target_file="$2"
  local tmp_file
  tmp_file="$(mktemp "${TMPDIR:-/tmp}/tool-help.man.XXXXXX")"

  man "$tool_name" 2>/dev/null | col -bx | /usr/bin/head -n 120 >"$tmp_file" 2>/dev/null || true
  if [[ -s "$tmp_file" ]]; then
    mv "$tmp_file" "$target_file"
    return 0
  fi

  rm -f "$tmp_file"
  return 1
}

tool_help_collect_sources() {
  local tool_name="$1"
  local source_dir="$2"
  local refresh="$3"
  local prefer_tealdeer="$4"
  local require_tealdeer="$5"
  local tldr_file help_file man_file

  mkdir -p "$source_dir"
  tldr_file=$(tool_help_source_file_for "$source_dir" "tldr")
  help_file=$(tool_help_source_file_for "$source_dir" "help")
  man_file=$(tool_help_source_file_for "$source_dir" "man")

  if (( refresh )); then
    rm -f "$tldr_file" "$help_file" "$man_file"
  fi

  if (( prefer_tealdeer )) && [[ ! -s "$tldr_file" ]]; then
    tool_help_collect_tldr "$tool_name" "$tldr_file" || true
  fi

  if (( require_tealdeer )) && [[ ! -s "$tldr_file" ]]; then
    return 1
  fi

  if [[ ! -s "$help_file" ]]; then
    tool_help_collect_help "$tool_name" "$help_file" || true
  fi

  if [[ ! -s "$man_file" ]]; then
    tool_help_collect_man "$tool_name" "$man_file" || true
  fi
}

tool_help_source_block() {
  local source_dir="$1"
  local kind="$2"
  local file
  file=$(tool_help_source_file_for "$source_dir" "$kind")
  [[ -s "$file" ]] || return 0

  printf '### %s\n\n' "${kind:u}"
  printf '```text\n'
  sed -n '1,160p' "$file"
  printf '\n```\n\n'
}

tool_help_context_collect() {
  TOOL_HELP_CONTEXT_CWD="$PWD"
  TOOL_HELP_CONTEXT_GIT_PRESENT=0
  TOOL_HELP_CONTEXT_GIT_ROOT=""
  TOOL_HELP_CONTEXT_ATUIN_AVAILABLE=0
  TOOL_HELP_CONTEXT_ATUIN_LAST=""

  if git rev-parse --show-toplevel >/dev/null 2>&1; then
    TOOL_HELP_CONTEXT_GIT_PRESENT=1
    TOOL_HELP_CONTEXT_GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
  fi

  if command -v atuin >/dev/null 2>&1; then
    TOOL_HELP_CONTEXT_ATUIN_AVAILABLE=1
    TOOL_HELP_CONTEXT_ATUIN_LAST=$(atuin history last 2>/dev/null | head -n 1 || true)
  fi

  return 0
}

tool_help_context_block() {
  local requested="$1"
  if (( ! requested )); then
    return 0
  fi

  /bin/cat <<EOF
## Current Context

- cwd: $(display_path "$TOOL_HELP_CONTEXT_CWD")
- inside git repo: $([[ "$TOOL_HELP_CONTEXT_GIT_PRESENT" == "1" ]] && printf 'yes' || printf 'no')
- git root: $([[ -n "$TOOL_HELP_CONTEXT_GIT_ROOT" ]] && display_path "$TOOL_HELP_CONTEXT_GIT_ROOT" || printf 'n/a')
- atuin available: $([[ "$TOOL_HELP_CONTEXT_ATUIN_AVAILABLE" == "1" ]] && printf 'yes' || printf 'no')
- last atuin command: ${TOOL_HELP_CONTEXT_ATUIN_LAST:-n/a}

EOF
}

tool_help_build_prompt() {
  local prompt_file="$1"
  local tool_name="$2"
  local question="$3"
  local source_dir="$4"
  local inventory_context="$5"
  local context_requested="$6"

  /bin/cat >"$prompt_file" <<EOF
Write a concise, practical Markdown answer for the terminal tool "${tool_name}".

User request:
${question}

Local install context:
- binary path: ${TOOL_HELP_BINARY_PATH:-unknown}
- version: ${TOOL_HELP_VERSION:-unknown}
${inventory_context:-"- Inventory entry not found."}

$(tool_help_context_block "$context_requested")
Use the grounded source material below as the primary truth. Do not invent flags or behavior that are not supported by the grounded material. If a useful detail is missing, say so briefly.

## Grounded Source Material

$(tool_help_source_block "$source_dir" "tldr")$(tool_help_source_block "$source_dir" "help")$(tool_help_source_block "$source_dir" "man")Requirements:
- Output Markdown only.
- Keep it practical and terminal-focused.
- Prefer short sections and concrete commands.
- Mention when guidance is grounded from tldr/help/man output.
EOF
}

write_meta_file() {
  local meta_file="$1"
  local source_dir="${TOOL_HELP_SOURCE_DIR:-}"
  local generated_at

  generated_at=$(/bin/date -u +"%Y-%m-%dT%H:%M:%SZ")

  /bin/cat >"$meta_file" <<EOF
tool = "$(toml_escape "${TOOL_HELP_TOOL:-unknown}")"
slug = "$(toml_escape "${TOOL_HELP_SLUG:-unknown}")"
provider = "$(toml_escape "${TOOL_HELP_PROVIDER_USED:-template}")"
model = "$(toml_escape "${TOOL_HELP_MODEL_USED:-}")"
mode = "$(toml_escape "${TOOL_HELP_MODE:-guide}")"
generated_at_utc = "$(toml_escape "$generated_at")"
binary_path = "$(toml_escape "$(display_path "${TOOL_HELP_BINARY_PATH:-unknown}")")"
version = "$(toml_escape "${TOOL_HELP_VERSION:-unknown}")"
ai_enriched = $([[ "${TOOL_HELP_AI_ENRICHED:-0}" == "1" ]] && printf 'true' || printf 'false')
grounded_only = $([[ "${TOOL_HELP_GROUNDED_ONLY:-0}" == "1" ]] && printf 'true' || printf 'false')
context_requested = $([[ "${TOOL_HELP_CONTEXT_REQUESTED:-0}" == "1" ]] && printf 'true' || printf 'false')
context_cwd = "$(toml_escape "$(display_path "${TOOL_HELP_CONTEXT_CWD:-}")")"
context_git_present = $([[ "${TOOL_HELP_CONTEXT_GIT_PRESENT:-0}" == "1" ]] && printf 'true' || printf 'false')
context_git_root = "$(toml_escape "$(display_path "${TOOL_HELP_CONTEXT_GIT_ROOT:-}")")"
context_atuin_available = $([[ "${TOOL_HELP_CONTEXT_ATUIN_AVAILABLE:-0}" == "1" ]] && printf 'true' || printf 'false')
context_atuin_last = "$(toml_escape "${TOOL_HELP_CONTEXT_ATUIN_LAST:-}")"
source_tldr = $([[ -n "$source_dir" && -s "$(tool_help_source_file_for "$source_dir" "tldr")" ]] && printf 'true' || printf 'false')
source_help = $([[ -n "$source_dir" && -s "$(tool_help_source_file_for "$source_dir" "help")" ]] && printf 'true' || printf 'false')
source_man = $([[ -n "$source_dir" && -s "$(tool_help_source_file_for "$source_dir" "man")" ]] && printf 'true' || printf 'false')
EOF
}

read_meta_value() {
  local meta_file="$1"
  local key="$2"

  [[ -r "$meta_file" ]] || return 0
  /usr/bin/awk -F'= ' -v key="$key" '
    $1 == key {
      value = $2
      gsub(/^"/, "", value)
      gsub(/"$/, "", value)
      print value
      exit
    }
  ' "$meta_file"
}
