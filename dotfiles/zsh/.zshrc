[[ -o interactive ]] || return

[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
[ -s "$HOME/.bun/_bun" ] && . "$HOME/.bun/_bun"

if [[ -z "${CLI_TOOL_STACK_GENERATING:-}" && -x "$HOME/.local/bin/update-cli-tool-stack" ]]; then
  if [[ ! -e "$HOME/CLI_TOOL_STACK.md" || "$HOME/.zshrc" -nt "$HOME/CLI_TOOL_STACK.md" || "$HOME/.local/bin/update-cli-tool-stack" -nt "$HOME/CLI_TOOL_STACK.md" ]]; then
    "$HOME/.local/bin/update-cli-tool-stack" >/dev/null 2>&1
  fi
fi

# Isolated Zed Editor Launcher
alias zediso='/Applications/Zed.app/Contents/MacOS/zed --user-data-dir ~/ZedIsolated'

# ZSH UI and Completions
autoload -Uz compinit colors add-zsh-hook
compinit
colors
zmodload zsh/datetime

setopt auto_cd
setopt interactive_comments
setopt hist_ignore_dups
setopt share_history
setopt complete_in_word
setopt no_beep
setopt prompt_subst
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# Quick Navigation Aliases
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
  
# Tmux Functions
ta() {
  tmux attach -t main 2>/dev/null || tmux new -s main
}

tn() {
  local name=${1:-scratch}
  tmux new -s "$name"
}
 
# Custom Terminal Widgets
terminal_hints_widget() {
  terminal-hints
  zle reset-prompt
}

zle -N terminal_hints_widget
bindkey '^G' terminal_hints_widget
bindkey '^[g' terminal_hints_widget

# Safe baseline: keep terminal startup minimal and avoid automatic UI mutations.
# Run `hello-terminal` manually if you want the banner.
# if [[ -o interactive && -z "${TMUX:-}" && "${TERM:-}" != "dumb" ]]; then
#   terminal-hello
# fi

# ====================================================================
# MODERN TERMINAL TOOLS (RUST-BASED)
# ====================================================================

# Eza (Replaces standard 'ls' with icons and colors)
alias ls='eza --icons'
alias ll='eza -lah --icons --git'
alias tree='eza --tree --icons'

# Standard Aliases
alias gs='git status -sb'   
alias tls='tmux ls'
alias tlg='terminal-guide'
alias tlh='terminal-hints'
alias udf='~/dotfiles/bin/update-dotfile'
alias treload='tmux source-file ~/.tmux.conf'
alias hello-terminal='terminal-hello'
alias blk='terminal-blocks-browser'
alias blc='terminal-block-copy-latest-command'
alias blo='terminal-block-copy-latest-output'
alias blb='terminal-block-bookmark-latest'
alias ccat='bat --paging=never --style=plain'
alias catp='bat --paging=always --style=numbers,changes,header'
alias ff='fd'
alias bt='btm'
alias br='broot'
alias yy='yazi'
alias gi='gitui'
alias skh='sk'

# Zoxide (Replaces 'cd' with smart jumps)
eval "$(zoxide init zsh)"

# Atuin (Searchable, ranked shell history)
eval "$(atuin init zsh)"

blr() {
  local cmd
  cmd=$("$HOME/.local/bin/terminal-block-rerun-latest")
  [[ -n "$cmd" ]] && print -z -- "$cmd"
}

mux() {
  ta
}

# Starship (Replaces the manual PROMPT and vcs_info)
eval "$(starship init zsh)"

# Replace standard tab completion with fzf-tab dropdowns
[ -r "/opt/homebrew/opt/fzf-tab/share/fzf-tab/fzf-tab.zsh" ] && source "/opt/homebrew/opt/fzf-tab/share/fzf-tab/fzf-tab.zsh"

# Enable live previews for folders (using eza) and files (using cat)
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:complete:*:*' fzf-preview 'if [ -d $realpath ]; then eza -1 --color=always $realpath; else cat $realpath 2>/dev/null | head -n 20; fi'

# ====================================================================
# BLOCKS
# ====================================================================
typeset -g TERMINAL_BLOCKS_DIR="$HOME/.local/state/terminal-blocks"
typeset -g TERMINAL_BLOCK_ACTIVE=0
typeset -g TERMINAL_BLOCK_ID=""
typeset -g TERMINAL_BLOCK_COMMAND=""
typeset -g TERMINAL_BLOCK_CWD=""
typeset -g TERMINAL_BLOCK_OUTPUT_FILE=""
typeset -gF TERMINAL_BLOCK_STARTED_AT=0

terminal_blocks_enabled() {
  [[ -o interactive && -t 1 && "${TERM:-}" != "dumb" ]]
}

terminal_block_emit_mark() {
  terminal_blocks_enabled || return
  printf '\033]133;%s\007' "$1" >/dev/tty 2>/dev/null || true
}

terminal_block_snapshot_output() {
  local output_file="$1"
  [[ -n "$output_file" ]] || return 1

  if [[ -n "${TMUX:-}" ]]; then
    tmux capture-pane -pS - > "$output_file" 2>/dev/null && return 0
  fi

  return 1
}

terminal_blocks_skip() {
  local -a words
  local cmd=""
  words=(${(z)1})

  for word in "${words[@]}"; do
    case "$word" in
      sudo|command|env|noglob|nocorrect|builtin)
        continue
        ;;
      *)
        cmd="$word"
        break
        ;;
    esac
  done

  case "$cmd" in
    codex|claude|opencode|command_palette|switch_theme|terminal-hints|terminal-guide|terminal-block*|clear|reset-prompt|\
    vim|nvim|vi|view|less|more|man|fzf|fzf-tmux|tmux|ssh|sftp|scp|mosh|screen|\
    top|htop|btop|btm|watch|tig|lazygit|gitui|ranger|yazi|lf|nnn|k9s|lazydocker)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

terminal_block_preexec() {
  terminal_blocks_enabled || return
  terminal_blocks_skip "$1" && return

  local sanitized_command="${1//$'\n'/ ; }"
  sanitized_command="${sanitized_command//$'\t'/ }"
  local block_day block_id
  block_day=$(date +%Y-%m-%d)
  block_id="$(date +%Y%m%d-%H%M%S)-$RANDOM"

  mkdir -p "$TERMINAL_BLOCKS_DIR/$block_day"

  TERMINAL_BLOCK_ID="$block_id"
  TERMINAL_BLOCK_COMMAND="$sanitized_command"
  TERMINAL_BLOCK_CWD="$PWD"
  TERMINAL_BLOCK_STARTED_AT=$EPOCHREALTIME
  TERMINAL_BLOCK_OUTPUT_FILE="$TERMINAL_BLOCKS_DIR/$block_day/$block_id.full.log"

  terminal_block_emit_mark "B"
  print -P ""
  print -P "%F{240}┌[%f%F{248}$TERMINAL_BLOCK_ID%f%F{240}]%f  %F{244}%D{%H:%M:%S}%f  %F{246}${TERMINAL_BLOCK_CWD/#$HOME/~}%f"
  print -P "%F{240}│%f %F{255}$sanitized_command%f"
  print -P "%F{240}│%f"
  terminal_block_emit_mark "C"
  TERMINAL_BLOCK_ACTIVE=1
}

terminal_block_precmd() {
  local exit_status=$?
  terminal_blocks_enabled || return $exit_status
  if [[ $TERMINAL_BLOCK_ACTIVE -ne 1 ]]; then
    terminal_block_emit_mark "A"
    return $exit_status
  fi

  local timestamp duration status_label status_color index_file
  typeset -F 3 duration
  duration=$(( EPOCHREALTIME - TERMINAL_BLOCK_STARTED_AT ))
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  index_file="$TERMINAL_BLOCKS_DIR/index.tsv"

  if (( exit_status == 0 )); then
    status_label="ok"
    status_color="114"
  else
    status_label="err:$exit_status"
    status_color="203"
  fi

  mkdir -p "$TERMINAL_BLOCKS_DIR"
  terminal_block_snapshot_output "$TERMINAL_BLOCK_OUTPUT_FILE" || TERMINAL_BLOCK_OUTPUT_FILE=""
  printf '%s\t%s\t%s\t%.3f\t%s\t%s\t%s\n' \
    "$TERMINAL_BLOCK_ID" \
    "$timestamp" \
    "$status_label" \
    "$duration" \
    "$TERMINAL_BLOCK_CWD" \
    "$TERMINAL_BLOCK_COMMAND" \
    "$TERMINAL_BLOCK_OUTPUT_FILE" >> "$index_file"

  printf '%s\n' "$TERMINAL_BLOCK_ID" > "$TERMINAL_BLOCKS_DIR/latest-id.txt"
  printf '%s\n' "$TERMINAL_BLOCK_COMMAND" > "$TERMINAL_BLOCKS_DIR/latest-command.txt"
  printf '%s\n' "$TERMINAL_BLOCK_OUTPUT_FILE" > "$TERMINAL_BLOCKS_DIR/latest-output-path.txt"

  terminal_block_emit_mark "D;$exit_status"
  print -P "%F{240}└[%f%F{$status_color}$status_label%f%F{240}]%f  %F{244}${duration}s%f  %F{245}blk%f browse  %F{245}blc%f cmd  %F{245}blo%f out  %F{245}blb%f mark"
  terminal_block_emit_mark "A"

  TERMINAL_BLOCK_ACTIVE=0
  TERMINAL_BLOCK_ID=""
  TERMINAL_BLOCK_COMMAND=""
  TERMINAL_BLOCK_CWD=""
  TERMINAL_BLOCK_OUTPUT_FILE=""
  return $exit_status
}

# Safe baseline: disable automatic terminal block hooks.
# Keep the functions defined so they can be re-enabled intentionally later.
# add-zsh-hook preexec terminal_block_preexec
# add-zsh-hook precmd terminal_block_precmd

# ====================================================================
# GHOSTTY THEME SWITCHER
# ====================================================================
switch_theme() {
  local ghostty_bin="/Applications/Ghostty.app/Contents/MacOS/ghostty"
  local selected_theme
  selected_theme=$("$ghostty_bin" +list-themes --plain | sed 's/ (resources)$//' | fzf \
    --prompt="󰏘 Theme: " \
    --pointer="󰅂" \
    --border=block \
    --info=hidden \
    --height=50% \
    --reverse \
    --preview='printf "Ghostty themes\n\nMove up and down to preview live.\nPress Enter to save.\nPress Esc to revert.\n"' \
    --preview-window='up,5,border-bottom,wrap' \
    --bind "start:execute-silent:$HOME/.local/bin/ghostty-theme-revert" \
    --bind "focus:execute-silent:$HOME/.local/bin/ghostty-theme-preview {}" \
    --bind "esc:execute-silent:$HOME/.local/bin/ghostty-theme-revert")

  if [[ -n "$selected_theme" ]]; then
    "$HOME/.local/bin/ghostty-theme-save" "$selected_theme"
  else
    "$HOME/.local/bin/ghostty-theme-revert"
  fi

  clear
}

# ====================================================================
# CUSTOM COMMAND PALETTE (Press Ctrl + /)
# ====================================================================
palette_style() {
  case "$1" in
    ghostty) printf '\033[38;5;172mghostty\033[0m' ;;
    tmux) printf '\033[38;5;67mtmux\033[0m' ;;
    blocks) printf '\033[38;5;179mblocks\033[0m' ;;
    history) printf '\033[38;5;81mhistory\033[0m' ;;
    workspace) printf '\033[38;5;74mworkspace\033[0m' ;;
    files) printf '\033[38;5;150mfiles\033[0m' ;;
    navigation) printf '\033[38;5;108mnavigation\033[0m' ;;
    dev) printf '\033[38;5;139mdev\033[0m' ;;
    *) printf '%s' "$1" ;;
  esac
}

command_palette_execute() {
  case "$1" in
    switch_theme)
      switch_theme
      zle reset-prompt
      ;;
    *)
      BUFFER="$1"
      zle accept-line
      ;;
  esac
}

command_palette() {
  local entries=(
    "ghostty|switch_theme|󰏘|Change Ghostty color theme"
    "ghostty|tlh|󰋼|Open quick terminal hints"
    "ghostty|tlg||Open full terminal guide"
    "ghostty|hello-terminal||Redraw startup banner"
    "tmux|mux||Open the default workspace multiplexer"
    "tmux|ta||Attach or create main tmux fallback session"
    "tmux|tn work||Create tmux fallback session named work"
    "tmux|treload||Reload tmux config"
    "tmux|tls||List tmux fallback sessions"
    "blocks|blk|󰆍|Browse recorded command blocks"
    "blocks|blc||Copy latest command"
    "blocks|blo||Copy latest output"
    "blocks|blb||Bookmark latest block"
    "blocks|blr|󰑐|Re-input latest command"
    "history|atuin search -i|󰋚|Open Atuin interactive history search"
    "history|atuin stats|󱕍|Show shell history stats"
    "history|atuin sync|󱞩|Sync encrypted history"
    "files|ccat ~/.zshrc|󰈙|Preview a file with bat"
    "files|ff . zshrc|󰱼|Find paths with fd"
    "files|skh|󰘫|Open skim fuzzy finder"
    "files|br|󰙅|Open broot file tree"
    "files|yy|󰇥|Open Yazi file manager"
    "files|bt|󰓅|Open bottom system monitor"
    "files|gi|󰊢|Open gitui"
    "navigation|eza -lah|󰉋|List files and directories"
    "navigation|z ..||Jump up with zoxide"
    "dev|zediso|󰅪|Launch isolated Zed editor"
    "dev|brew update|󰚰|Update Homebrew packages"
  )

  local formatted=()
  local entry group cmd icon description label
  for entry in "${entries[@]}"; do
    IFS='|' read -r group cmd icon description <<< "$entry"
    label=$(palette_style "$group")
    formatted+=("[$label] $cmd :: $icon  $description")
  done

  local selection=$(printf "%b\n" "${formatted[@]}" | fzf \
    --ansi \
    --prompt="󰘧 " \
    --pointer="󰅂" \
    --border=block \
    --info=hidden \
    --height=55% \
    --reverse \
    --preview="$HOME/.local/bin/command-palette-preview {}" \
    --preview-window='up,8,border-bottom,wrap')

  cmd=$(printf "%s\n" "$selection" | sed -E 's/\x1B\[[0-9;]*[A-Za-z]//g' | sed -E 's/^\[[^]]+\] //' | awk -F' :: ' '{print $1}')

  if [[ -n "$cmd" ]]; then
    command_palette_execute "$cmd"
  fi
}

zle -N command_palette
# Bind to Ctrl + / (Terminal translates this to ^_)
bindkey '^_' command_palette 

# Bind to Ctrl + P (Standard Editor Command Palette)
bindkey '^p' command_palette

# ZSH Plugins (THESE MUST REMAIN AT THE VERY BOTTOM)
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

source /Users/vorposa/.config/broot/launcher/bash/br
