#!/bin/zsh

tool_help_provider_generate() {
  local out_file="$1"
  local prompt_file="$2"

  command -v codex >/dev/null 2>&1 || return 1

  local -a args
  args=(
    codex exec
    --skip-git-repo-check
    --ephemeral
    --color never
    -C "$TOOL_HELP_DOTFILES_DIR"
    -o "$out_file"
  )

  [[ -n "${TOOL_HELP_MODEL_USED:-}" ]] && args+=(-m "$TOOL_HELP_MODEL_USED")

  "${args[@]}" <"$prompt_file"
}
