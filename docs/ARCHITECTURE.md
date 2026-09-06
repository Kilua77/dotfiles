# Architecture

How this repository is put together, in one page.

## The chezmoi model in five lines

1. The **source directory** (this repo, cloned to `~/.local/share/chezmoi` by
   `chezmoi init`) is the only source of truth; everything under `$HOME` is
   generated from it by `chezmoi apply`.
2. Source names map to targets: `dot_zshrc` -> `~/.zshrc`, `private_x` ->
   mode 0600, `executable_x` -> mode 0755; a `.tmpl` suffix means the file is a
   Go template rendered at apply time.
3. Scripts live in `.chezmoiscripts/`; chezmoi recognizes them by the `#!`
   shebang in their **rendered** output, so every template here must emit a
   shebang on line 1 in all branches.
4. `run_once_` scripts run at most once per machine (tracked in chezmoi's
   state database); `run_onchange_` scripts re-run whenever the sha256 of
   their rendered content changes. `before_`/`after_` position them
   before/after the file-copy phase; within a phase, scripts run in lexical
   order (hence the numeric prefixes).
5. `.chezmoiignore` (itself a template) lists what is never deployed;
   `.chezmoiexternal.toml` fetches pinned archives into `$HOME`;
   `.chezmoidata/*.yaml` provides plain data reachable as template variables
   like `.versions.*`.

## The two rules of this repo

### Rule 1: OS differences via `.chezmoi.os` only -- everything else via runtime guards

`.chezmoi.os` (render-time) is used when the correct *action* differs per OS:

```text
{{ if ne .chezmoi.os "darwin" -}}   # brew bundle script renders as a no-op
{{ if eq .chezmoi.os "darwin" -}}   # credential helper = osxkeychain
```

Runtime guards are used when absence is an *environment condition* on the
same OS -- a tool that may or may not be installed:

```sh
command -v apt-get >/dev/null 2>&1 || exit 0   # silent no-op on non-apt distros
command -v code  >/dev/null 2>&1 || exit 0     # WARN once, then no-op
```

How to pick: if both platforms could sensibly run the same command, guard at
runtime; if one platform needs entirely different commands (or the script's
interpreter differs), branch on `.chezmoi.os`. Render-time branches keep each
script single-purpose; runtime guards keep a script self-describing about its
preconditions. Never test OS with `uname` in scripts -- chezmoi already knows.

One consequence: an OS-branched template must still render a valid script
(shebang + `exit 0`) on the "wrong" OS, so chezmoi sees and tracks it. Every
template here follows that pattern.

### Rule 2: version pins live only in `.chezmoidata/versions.yaml`

No version number appears anywhere else. The pins flow two ways:

- zsh plugins: `versions.yaml` -> URLs in `.chezmoiexternal.toml` (archives
  re-download when the URL, i.e. the version, changes).
- Neovim on Linux: `versions.yaml` -> the tarball URL rendered inside
  `run_onchange_after_12-neovim-linux.sh.tmpl` (which makes the script's
  content -- and therefore its run_onchange hash -- change on every bump).

Bumping anything is a one-line edit followed by `chezmoi apply`.

## The script pipeline

`chezmoi apply` runs, in order:

| # | Script | Phase | Purpose |
|---|---|---|---|
| 00 | `run_once_before_00-backup-migration` | before files | back up soon-to-be-overwritten dotfiles |
| 10 | `run_onchange_after_10-brew-bundle` | after files | macOS: `brew bundle` (hash of `Brewfile`) |
| 11 | `run_onchange_after_11-apt-packages` | after files | Linux: apt packages, uv, Debian alternatives |
| 12 | `run_onchange_after_12-neovim-linux` | after files | Linux: pinned Neovim >= 0.10 tarball |
| 20 | `run_onchange_after_20-vscode-extensions` | after files | generic VS Code extensions (flag-gated) |
| 30 | `run_once_after_30-gitconfig-local` | after files | create `~/.gitconfig.local` if absent |
| 40 | `run_onchange_after_40-vcpkg-bootstrap` | after files | clone + bootstrap `~/vcpkg` (flag-gated) |

`before_` scripts run before any file is touched (backup needs that);
`after_` scripts run once the dotfiles they depend on (PATH, config) exist.
Within each phase the numeric prefixes force a deterministic, readable order.

All scripts are idempotent and failure-tolerant: individual failures print
`WARN:` and the apply continues. Scripts never abort on a missing tool.

## Where each concern lives

| Concern | Source files |
|---|---|
| Shell | `dot_zshrc.tmpl`, plugin pins in `.chezmoidata/versions.yaml` + `.chezmoiexternal.toml`, prompt config in `.chezmoi.toml.tmpl` |
| Git | `dot_gitconfig.tmpl` (shared), `.chezmoiscripts/run_once_after_30-*` (machine-local part) |
| Neovim | `dot_config/nvim/` (editor config), `.chezmoiscripts/run_onchange_after_12-*` (Linux binary) |
| C/C++ toolchain | `Brewfile` (macOS), `.chezmoiscripts/run_onchange_after_11-*` (Linux), `dot_clang-format` / `dot_clang-tidy` |
| AI tooling | **not here** -- private overlay, see [ai-overlay.md](ai-overlay.md) |
| Install scripts | `.chezmoiscripts/` (table above) |
| CI | `.github/workflows/lint.yml` (gitleaks, shellcheck, template render) |

## The private overlay

Everything private (AI assistant config, keys plumbing) is kept out of this
public repo and applied as a second chezmoi layer. The pattern, and what the
overlay expects from this repo (e.g. the `~/.localrc` variables), is
described in [ai-overlay.md](ai-overlay.md).
