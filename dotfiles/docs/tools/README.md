# Tool Guides

This folder holds generated, tool-specific guides created by `tool-help`.

## Purpose

This is the saved knowledge layer for terminal tools in this dotfiles setup.

It is meant to be:

- terminal-first
- grounded before enriched
- generated on demand
- easy to cache and revisit
- simple enough to extend later into a richer local wiki

The intended workflow is:

1. run `tool-help <tool>` when you want to learn or recall a tool
2. read the answer inline in the terminal
3. let `tool-help` save the result here for later reuse
4. ask focused follow-up questions and let those accumulate under `queries/`

## Usage

Base guide:

```sh
tool-help tmux
```

Grounded-only guide:

```sh
tool-help --ground-only tmux
```

Focused follow-up:

```sh
tool-help tmux how do i detach and reattach
```

Force regeneration:

```sh
tool-help --refresh tmux
```

List saved tool guides:

```sh
tool-help --list
```

Short alias:

```sh
th tmux
```

Context-aware guide seed:

```sh
tool-help --context gitui
```

## Provider Behavior

`tool-help` supports provider selection through `--provider`.

Current modes:

- `auto`: default; uses the configured default provider
- `opencode`: default AI backend for enrichment
- `codex`: alternate AI backend
- `template`: local formatting fallback that uses grounded local sources only

Examples:

```sh
tool-help --provider auto tmux
tool-help --provider opencode --model openai/gpt-5.4-mini yazi
tool-help --provider codex yazi
tool-help --provider template fd
```

Grounding order:

1. cached guide
2. saved local sources
3. `tldr` / `tealdeer`
4. `<tool> --help`
5. `man <tool> | head -n 120`
6. optional AI enrichment

Config path:

```sh
~/.config/tool-help/config.toml
```

Layout:

- `docs/tools/<tool>/guide.md`: the current saved guide for a tool
- `docs/tools/<tool>/request.txt`: the latest query used to generate a guide
- `docs/tools/<tool>/meta.toml`: metadata about the current saved guide
- `docs/tools/<tool>/sources/tldr.txt`: grounded `tldr` or `tealdeer` output if available
- `docs/tools/<tool>/sources/help.txt`: grounded `--help` output if available
- `docs/tools/<tool>/sources/man.txt`: grounded `man` excerpt if available
- `docs/tools/<tool>/queries/<timestamp>.request.txt`: a saved focused follow-up question
- `docs/tools/<tool>/queries/<timestamp>.md`: the saved answer for that focused question
- `docs/tools/<tool>/queries/<timestamp>.toml`: metadata for that focused follow-up answer

Notes:

- These files are generated on demand.
- They are reference material, not the source of truth for shell configuration.
- `~/dotfiles` remains the canonical place to edit configuration and helper scripts.
- The structure is intentionally simple so it can grow later into a richer local wiki.
- The first request for a tool becomes its saved guide.
- Later focused questions are stored under `queries/` if a base guide already exists.
- `--context` is intentionally thin in this phase; it captures current shell context without adding any automatic recommendation engine yet.
