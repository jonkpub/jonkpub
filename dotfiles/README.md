# dotfiles

Personal environment setup for this machine.

## Layout

- `zsh/.zshenv`
- `zsh/.zprofile`
- `zsh/.zshrc`
- `zsh/.profile`
- `tmux/.tmux.conf`
- `git/.gitconfig`
- `config/atuin/config.toml`
- `config/broot/conf.hjson`
- `config/broot/verbs.hjson`
- `config/starship.toml`
- `config/gh/config.yml`
- `config/codex-orchestrator/config.json`
- `docs/CLI_TOOL_STACK.md`
- `AGENT_CONTEXT.md`
- `Brewfile`
- `bin/sync-jonkpub-dotfiles`
- `bin/update-dotfile`
- `bin/update-cli-tool-stack`

## Usage

Apply the repo-backed home stubs:

```sh
~/dotfiles/install.sh
```

Install Homebrew packages declared in the Brewfile:

```sh
brew bundle --file ~/dotfiles/Brewfile
```

Refresh the CLI inventory manually:

```sh
~/dotfiles/bin/update-cli-tool-stack
```

The generated inventory is also copied into the repo at:

```sh
~/dotfiles/docs/CLI_TOOL_STACK.md
```

Mirror the current working copy into the `jonkpub/jonkpub` profile repo subtree:

```sh
~/dotfiles/bin/sync-jonkpub-dotfiles
```

You can override the target clone location if needed:

```sh
JONKPUB_REPO_DIR=~/some/other/jonkpub ~/dotfiles/bin/sync-jonkpub-dotfiles
```

Sync, commit, and push the mirrored subtree in one step:

```sh
~/dotfiles/bin/update-dotfile
```

## Notes

- The repo-backed files are the canonical source of truth.
- The home-directory dotfiles are thin stubs that source or include these files.
- Selected files in `~/.config` are symlinked back to this repo by `install.sh`.
- `fzf-tab` is installed through Homebrew rather than vendored in this repo.
- Secret-bearing or machine-local files are intentionally excluded, for example `~/.config/gh/hosts.yml`.
- `CLI_TOOL_STACK.md` is a generated reference, not the source of truth.
- `AGENT_CONTEXT.md` is curated guidance for workflow, preferences, and publishing rules.
