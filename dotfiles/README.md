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
- `config/tool-help/config.toml`
- `docs/CLI_TOOL_STACK.md`
- `docs/tools/README.md`
- `AGENT_CONTEXT.md`
- `Brewfile`
- `bin/tool-help`
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

Generate or view a saved tool guide from the terminal:

```sh
tool-help tmux
tool-help atuin how do i sync and search history effectively
```

Short alias:

```sh
th yazi
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

`update-dotfile` now commits the local `~/dotfiles` repo first, then mirrors that committed state into the profile repo subtree and pushes it.

## Tool Help

`tool-help` is the terminal-native guide system for this setup.

What it does:

- collects grounded source material before any optional AI enrichment
- generates inline Markdown help for a tool directly in the terminal
- saves the current guide under `~/dotfiles/docs/tools/<tool>/guide.md`
- saves the request that generated that guide under `~/dotfiles/docs/tools/<tool>/request.txt`
- saves grounded source material under `~/dotfiles/docs/tools/<tool>/sources/`
- saves focused follow-up answers under `~/dotfiles/docs/tools/<tool>/queries/`
- reuses the saved guide on later runs unless you force a refresh

Common commands:

```sh
tool-help tmux
tool-help zoxide
tool-help atuin how do i sync and search history effectively
tool-help --ground-only tmux
tool-help --no-ai fd
tool-help --context gitui
tool-help --refresh yazi
tool-help --list
```

How it behaves:

- `tool-help <tool>` generates a base guide the first time, then shows the cached guide on later runs.
- `tool-help <tool> some question` saves a focused follow-up answer if a base guide already exists.
- If no base guide exists yet, the first request becomes the saved guide for that tool.
- `tool-help --refresh <tool>` rebuilds the saved guide.
- `tool-help --ground-only <tool>` skips AI enrichment and formats the answer from saved local sources only.
- `tool-help --no-ai <tool>` behaves like a grounded local-only run without calling `opencode` or `codex`.
- `tool-help --context <tool>` gathers a thin context snapshot from the current shell environment and routes that through the same help pipeline.

Grounding pipeline:

1. cached guide
2. saved local source files
3. `tldr` / `tealdeer`
4. `<tool> --help`
5. `man <tool> | head -n 120`
6. optional AI enrichment

Providers:

- `auto`: default; prefers the configured default provider
- `opencode`: default AI backend for enrichment
- `codex`: alternate AI backend
- `template`: local formatting fallback used when AI is skipped or unavailable

Examples:

```sh
tool-help --provider opencode --model openai/gpt-5.4-mini tmux
tool-help --provider codex --model gpt-5.4 yazi
tool-help --provider template fd
tool-help --refresh atuin
```

Tracked config:

```sh
~/.config/tool-help/config.toml
```

This controls:

- default provider
- default model per provider
- whether AI enrichment is enabled by default
- whether `tealdeer` is preferred or required

Saved output layout:

- `~/dotfiles/docs/tools/<tool>/guide.md`
- `~/dotfiles/docs/tools/<tool>/request.txt`
- `~/dotfiles/docs/tools/<tool>/meta.toml`
- `~/dotfiles/docs/tools/<tool>/sources/tldr.txt`
- `~/dotfiles/docs/tools/<tool>/sources/help.txt`
- `~/dotfiles/docs/tools/<tool>/sources/man.txt`
- `~/dotfiles/docs/tools/<tool>/queries/<timestamp>.md`
- `~/dotfiles/docs/tools/<tool>/queries/<timestamp>.request.txt`
- `~/dotfiles/docs/tools/<tool>/queries/<timestamp>.toml`

## Notes

- The repo-backed files are the canonical source of truth.
- The home-directory dotfiles are thin stubs that source or include these files.
- Selected files in `~/.config` are symlinked back to this repo by `install.sh`.
- `fzf-tab` is installed through Homebrew rather than vendored in this repo.
- Secret-bearing or machine-local files are intentionally excluded, for example `~/.config/gh/hosts.yml`.
- `CLI_TOOL_STACK.md` is a generated reference, not the source of truth.
- `docs/tools/` holds generated, tool-specific guides and grounded source captures created on demand by `tool-help`.
- `AGENT_CONTEXT.md` is curated guidance for workflow, preferences, and publishing rules.
