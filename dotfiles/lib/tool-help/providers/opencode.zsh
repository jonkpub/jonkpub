#!/bin/zsh

tool_help_provider_generate() {
  local out_file="$1"
  local prompt_file="$2"
  local prompt

  command -v opencode >/dev/null 2>&1 || return 1
  prompt=$(cat "$prompt_file")

  local -a args
  args=(
    opencode run
    --format default
    --dir "$TOOL_HELP_DOTFILES_DIR"
  )

  [[ -n "${TOOL_HELP_MODEL_USED:-}" ]] && args+=(-m "$TOOL_HELP_MODEL_USED")
  args+=("$prompt")

  "${args[@]}" >"$out_file"
}
