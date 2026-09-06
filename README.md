# dotfiles

Cross-platform dotfiles managed with [chezmoi](https://www.chezmoi.io), for a
C/C++ development workflow on macOS (Homebrew) and Linux (apt as the tested
baseline): zsh + starship + tmux, Neovim (LazyVim, pinned >= 0.10),
clangd/clang-format/clang-tidy, CMake/Ninja/vcpkg, and the usual modern CLI
set (fzf, ripgrep, eza, bat, git-delta, lazygit).

This repository is the **public plumbing** -- shell, git, editor and toolchain
configuration that is safe to share. Anything private (AI tool configuration,
API-key plumbing) lives in a separate private overlay applied on top of this
repo; see [docs/ai-overlay.md](docs/ai-overlay.md).

## Quickstart

### macOS

1. Install [Homebrew](https://brew.sh) if you do not have it yet:

   ```sh
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. Install chezmoi and apply this repo:

   ```sh
   brew install chezmoi
   chezmoi init --apply <github-user>/dotfiles
   ```

### Linux

```sh
sh -c "$(curl -fsSL https://chezmoi.io/get)" -- init --apply <github-user>/dotfiles
```

Replace `<github-user>/dotfiles` with the URL of your fork (an SSH URL like
`git@github.com:<github-user>/dotfiles.git` works too).

The first `chezmoi init --apply` prompts for the values below, runs a backup
of any existing dotfiles into `~/dotfiles-backup-<timestamp>/`, deploys the
files, then runs the install scripts. Re-running `chezmoi apply` later is
always safe and idempotent.

## First-run prompts

| Prompt | Config key | Used for |
|---|---|---|
| `Git user.name` | `name` | `[user] name` in `~/.gitconfig` |
| `Git user.email` | `email` | `[user] email` in `~/.gitconfig` |
| `Default C/C++ compiler (gcc/clang/none)` | `compiler` | `CC`/`CXX` exports in `~/.zshrc`; `none` leaves system defaults alone |

Answers are stored in `~/.config/chezmoi/chezmoi.toml` and never asked again.

## Secrets

Secrets never live in this repo. `~/.zshrc` sources `~/.localrc` if it exists:

```sh
cp ~/.localrc.example ~/.localrc   # after the first apply
chmod 600 ~/.localrc
```

`dot_localrc.example` documents the exact environment variables the private
AI overlay reads (API keys and similar). The file is listed in
`.chezmoiignore`, so chezmoi can never deploy or overwrite it by accident.

## What gets installed

| Concern | macOS | Linux |
|---|---|---|
| Packages | `brew bundle` from the `Brewfile` (zsh, neovim, starship, fzf, llvm, cmake, ...) | apt loop in `run_onchange_after_11` (zsh, ripgrep, cmake, clang tools, ...) |
| GUI apps | casks: VS Code, ghostty, JetBrains Mono Nerd Font | not managed (VS Code installs the same extensions) |
| Neovim | Homebrew formula | pinned official tarball >= 0.10 (distro packages are too old for LazyVim) |
| Python | system/brew | `uv` via official installer |
| C++ deps | vcpkg (optional) | vcpkg (optional) |

Non-apt Linux distros are silently skipped by the apt script; everything else
still applies.

## Feature flags

| Flag | Default | Effect when `true` |
|---|---|---|
| `vcpkg` | `true` | clone `~/vcpkg` + bootstrap after first apply |
| `vscode_extensions` | `true` | install the generic VS Code extension set |

To change either, edit `~/.config/chezmoi/chezmoi.toml` and re-run
`chezmoi apply`. Disabling a flag does not uninstall anything; it only stops
the corresponding script from acting.

## Repository layout

```text
.
├── .chezmoi.toml.tmpl          # first-run prompts (name/email/compiler/flags)
├── .chezmoiignore              # never-deployed files (itself a template)
├── .chezmoiexternal.toml       # pinned zsh plugin tarballs (no plugin manager)
├── .chezmoidata/
│   └── versions.yaml           # ALL version pins (single source of truth)
├── .chezmoiscripts/            # numbered install scripts, ordered:
│   ├── run_once_before_00-backup-migration.sh.tmpl
│   ├── run_onchange_after_10-brew-bundle.sh.tmpl
│   ├── run_onchange_after_11-apt-packages.sh.tmpl
│   ├── run_onchange_after_12-neovim-linux.sh.tmpl
│   ├── run_onchange_after_20-vscode-extensions.sh.tmpl
│   ├── run_once_after_30-gitconfig-local.sh.tmpl
│   └── run_onchange_after_40-vcpkg-bootstrap.sh.tmpl
├── Brewfile                    # macOS packages (brew bundle)
├── dot_zshrc.tmpl              # shell entry point
├── dot_gitconfig.tmpl          # git (includes ~/.gitconfig.local)
├── dot_localrc.example         # template for the ignored secrets file
├── docs/
│   ├── ARCHITECTURE.md         # how the repo fits together
│   ├── MAINTENANCE.md          # recipe book for common changes
│   └── ai-overlay.md           # the private overlay pattern
└── .github/workflows/lint.yml  # gitleaks + shellcheck + template render
```

## Making it yours

- Day-to-day changes (add a package, bump a version, add a plugin):
  [docs/MAINTENANCE.md](docs/MAINTENANCE.md).
- How the pieces fit together and the repo's two rules:
  [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Credits

Structure and some scripts originally derived from
[holman/dotfiles](https://github.com/holman/dotfiles) (MIT).
