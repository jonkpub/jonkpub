#!/bin/zsh

set -euo pipefail

DOTFILES_DIR="$HOME/dotfiles"

mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.config/atuin" "$HOME/.config/broot" "$HOME/.config/gh" "$HOME/.config/codex-orchestrator" "$HOME/.config/tool-help"

rm -f "$HOME/.local/bin/update-cli-tool-stack"
rm -f "$HOME/.local/bin/tool-help"
rm -f "$HOME/.config/atuin/config.toml"
rm -f "$HOME/.config/broot/conf.hjson"
rm -f "$HOME/.config/broot/verbs.hjson"
rm -f "$HOME/.config/starship.toml"
rm -f "$HOME/.config/gh/config.yml"
rm -f "$HOME/.config/codex-orchestrator/config.json"
rm -f "$HOME/.config/tool-help/config.toml"

ln -s "../../dotfiles/bin/update-cli-tool-stack" "$HOME/.local/bin/update-cli-tool-stack"
ln -s "../../dotfiles/bin/tool-help" "$HOME/.local/bin/tool-help"
ln -s "../../dotfiles/config/atuin/config.toml" "$HOME/.config/atuin/config.toml"
ln -s "../../dotfiles/config/broot/conf.hjson" "$HOME/.config/broot/conf.hjson"
ln -s "../../dotfiles/config/broot/verbs.hjson" "$HOME/.config/broot/verbs.hjson"
ln -s "../dotfiles/config/starship.toml" "$HOME/.config/starship.toml"
ln -s "../../dotfiles/config/gh/config.yml" "$HOME/.config/gh/config.yml"
ln -s "../../dotfiles/config/codex-orchestrator/config.json" "$HOME/.config/codex-orchestrator/config.json"
ln -s "../../dotfiles/config/tool-help/config.toml" "$HOME/.config/tool-help/config.toml"

cat >"$HOME/.zshenv" <<'EOF'
[ -r "$HOME/dotfiles/zsh/.zshenv" ] && . "$HOME/dotfiles/zsh/.zshenv"
EOF

cat >"$HOME/.zprofile" <<'EOF'
[ -r "$HOME/dotfiles/zsh/.zprofile" ] && . "$HOME/dotfiles/zsh/.zprofile"
EOF

cat >"$HOME/.zshrc" <<'EOF'
[ -r "$HOME/dotfiles/zsh/.zshrc" ] && . "$HOME/dotfiles/zsh/.zshrc"
EOF

cat >"$HOME/.profile" <<'EOF'
[ -r "$HOME/dotfiles/zsh/.profile" ] && . "$HOME/dotfiles/zsh/.profile"
EOF

cat >"$HOME/.tmux.conf" <<'EOF'
source-file "$HOME/dotfiles/tmux/.tmux.conf"
EOF

cat >"$HOME/.gitconfig" <<'EOF'
[include]
	path = ~/dotfiles/git/.gitconfig
EOF

echo "dotfiles installed"
