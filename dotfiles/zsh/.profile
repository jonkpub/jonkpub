# POSIX login shell environment.

path_prepend() {
  case ":$PATH:" in
    *":$1:"*) ;;
    *) PATH="$1:$PATH" ;;
  esac
}

path_prepend "/opt/homebrew/bin"
path_prepend "$HOME/.local/bin"
path_prepend "$HOME/.cargo/bin"
path_prepend "$HOME/.antigravity/antigravity/bin"
path_prepend "$HOME/.bun/bin"
path_prepend "$HOME/Library/pnpm"

export PATH
