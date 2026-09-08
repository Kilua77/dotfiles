# dotfiles

Personal dotfiles, organized as **topics**: one directory per subject, and a
bootstrap that makes adding things trivial. Drop a `*.zsh` file in a topic and
it gets sourced; drop a `*.symlink` file and it gets linked into `$HOME`.
No dotfile manager, no templating, no dependencies beyond git and a shell.

Adapted from [holman/dotfiles](https://github.com/holman/dotfiles) (MIT) —
the topic model and bootstrap mechanics are his; the modernizations are mine.

## Install

```sh
git clone <this repo> ~/.dotfiles
~/.dotfiles/script/bootstrap   # link dotfiles (asks for git name/email once)
~/.dotfiles/script/install     # packages + per-topic installers
```

## Topics

| Topic | What lives there |
|---|---|
| `zsh/` | shell: loader, options, plugins (pinned clones), aliases, prompt |
| `functions/` | autoloaded zsh functions (`c`, `gf`, `extract`) |
| `git/` | gitconfig, global ignore, local-override template |
| `tmux/` | tmux configuration |
| `nvim/` | Neovim (LazyVim) as the fast terminal editor |
| `cpp/` | C++ toolchain: clang-format/tidy, ccache, project generator |
| `apt/` | Linux package list + installer |
| `vscode/` | VS Code extension set (generic) |
| `claude/` | AI-assistant hook plumbing (generic) |
| `bin/` | scripts on PATH — `dot` updates everything |

## How it works

- `script/bootstrap` links `*.symlink` files:
  `topic/foo.symlink → ~/.foo`, `topic/config/x.symlink → ~/.config/x`,
  `topic/home/x.symlink → ~/x`; the same rules under `topic/darwin/` or
  `topic/linux/` apply only on the matching OS.
- `zsh/zshrc.symlink` sources every `*/*.zsh` (path files first, completions
  last) — add a file, it is live.
- `script/install` runs `brew bundle` (macOS) then each topic's `install.sh`.
- Secrets and machine flags live in `~/.localrc` (never committed) — see
  `zsh/localrc.example`.

Docs: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) ·
[docs/OVERLAY.md](docs/OVERLAY.md) (run a private layer on top) ·
[docs/MAINTENANCE.md](docs/MAINTENANCE.md) ·
[docs/PORTING.md](docs/PORTING.md) (full 2016→2026 porting audit).
