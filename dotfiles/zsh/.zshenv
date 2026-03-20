# Minimal zsh environment shared by interactive and non-interactive shells.
# Keep this file fast and side-effect free.

typeset -U path PATH

export BUN_INSTALL="$HOME/.bun"
export NVM_DIR="$HOME/.nvm"
export PNPM_HOME="$HOME/Library/pnpm"

path=(
  /opt/homebrew/bin
  "$HOME/.local/bin"
  "$HOME/.cargo/bin"
  "$HOME/.antigravity/antigravity/bin"
  "$BUN_INSTALL/bin"
  "$PNPM_HOME"
  $path
)

path=(${path:#\~/.dotnet/tools})
[[ -d "$HOME/.dotnet/tools" ]] && path=("$HOME/.dotnet/tools" $path)

export PATH
