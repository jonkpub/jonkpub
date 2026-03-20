#!/bin/zsh

tool_help_provider_generate() {
  local out_file="$1"
  local _prompt_file="$2"
  local source_dir="${TOOL_HELP_SOURCE_DIR:-}"
  local path="${TOOL_HELP_BINARY_PATH:-unknown}"
  local version="${TOOL_HELP_VERSION:-unknown}"
  local tldr_block help_block man_block

  tldr_block="$(tool_help_source_block "$source_dir" "tldr")"
  help_block="$(tool_help_source_block "$source_dir" "help")"
  man_block="$(tool_help_source_block "$source_dir" "man")"

  /bin/cat >"$out_file" <<EOF
# ${TOOL_HELP_TOOL}

## What It Is

${TOOL_HELP_TOOL} is part of your terminal tool stack. This answer is formatted locally from grounded command help instead of a live AI backend.

## Grounded Sources Used

- tldr/tealdeer: $([[ -s "$(tool_help_source_file_for "$source_dir" "tldr")" ]] && printf 'yes' || printf 'no')
- --help: $([[ -s "$(tool_help_source_file_for "$source_dir" "help")" ]] && printf 'yes' || printf 'no')
- man: $([[ -s "$(tool_help_source_file_for "$source_dir" "man")" ]] && printf 'yes' || printf 'no')

## Practical Notes

- Binary path: \`${path/#$HOME/~}\`
- Version: \`${version}\`
- Request focus: ${TOOL_HELP_QUERY}

## Grounded Excerpts

${tldr_block}

${help_block}

${man_block}
## Next Things To Try

\`\`\`sh
${TOOL_HELP_TOOL} --help
man ${TOOL_HELP_TOOL} 2>/dev/null || true
\`\`\`
EOF
}
