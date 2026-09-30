# Architecture

One mental model, three mechanisms. Everything else is convention.

## The topic model

The repository is a set of **topic directories** — one directory per subject
(`zsh/`, `git/`, `tmux/`, `nvim/`, `cpp/`, …). Two things happen with a topic:

- Every `*/*.zsh` file is **sourced** by `zsh/zshrc.symlink` when a shell
  starts. Add a file, it is live. No registration, no import list.
- Every `*.symlink` file is **linked into `$HOME`** by `script/bootstrap`.
  Add a file, run bootstrap (or `bin/dot`), it is deployed.

`bin/` is a topic of a third kind: its contents go on `PATH` directly
(`zsh/path.zsh`), no symlinking involved.

This is the model popularized by [holman/dotfiles](https://github.com/holman/dotfiles),
which this repo forks conceptually. The bootstrap here extends it with XDG
paths and OS subtrees (below).

## Linking conventions (script/bootstrap)

| Rule | Source | Target |
|---|---|---|
| R1 | `<topic>/<name>.symlink` | `~/.<name>` |
| R2 | `<topic>/config/<path>.symlink` | `~/.config/<path>` (parents created; a *directory* named `foo.symlink` links as a whole tree — used by `nvim/`) |
| R3 | `<topic>/home/<path>.symlink` | `~/<path>` — for nested dot-paths (`ssh/home/.ssh/config.symlink` → `~/.ssh/config`) |
| R4 | the same rules under `<topic>/darwin/` or `<topic>/linux/` | applied **only** on the matching OS (`darwin` = `uname -s` is Darwin; `linux` = everything else, kept generic) |

Anything that is not a `*.symlink` file is never linked — exclusion by
construction, not by blacklist. `*.zsh`, `install.sh`, `README.md`,
`*.example` files are inert by design.

Conflict policy: an existing target (file, directory, foreign or broken
symlink) is **backed up** to `~/.dotfiles-backup/<stamp>/` and then replaced
(`--force` skips the backup; `--dry-run` reports without touching).
`XDG_CONFIG_HOME` is honored only when it points inside `$HOME`.

On first run, bootstrap also generates `~/.gitconfig.local` (0600) from
`git/gitconfig.local.symlink.example`, prompting for name/email — the main
`gitconfig.symlink` contains no identity.

## Shell load order (zsh/zshrc.symlink)

The loader is a contract; do not add behavior to it, add a topic file.

1. `~/.localrc` — secrets and machine flags, first (needs nothing)
2. every `*/path.zsh` — PATH setup before anything runs
3. every other `*/*.zsh` except `path.zsh`/`completion.zsh`, in
   deterministic alphabetical topic order
4. `autoload -Uz compinit && compinit` — after fpath files, before completions
5. every `*/completion.zsh` — completion tuning, last

Within topic 3, ordering constraints are internal to the files:
`zsh/plugins.zsh` loads the pinned plugins in strict order (autosuggestions →
syntax-highlighting → history-substring-search **last**, then its bindkeys),
`zsh/tools.zsh` (prompt/zoxide/fzf) after them. The glob is depth-1 per topic
(`$DOTFILES/*/*.zsh`), deliberately not recursive.

## Install flow (script/install)

1. `brew bundle` on the root `Brewfile` — `brew` itself is the OS guard
   (absent on Linux), and the file is **hash-gated** (see below).
2. Every `*/install.sh` in deterministic alphabetical topic order, each run
   from its own topic directory; a failure logs a WARN and does not stop the
   others. On Linux that includes the `local/` topic, which owns every tool
   the install delivers (see below).

`bin/dot` chains the three commands: `git pull --ff-only` (when a remote
exists) → `script/bootstrap "$@"` → `script/install`.

## The local layer (Linux userland)

Everything the install delivers on Linux lands under `~/.local` — **no
apt, no dnf, no sudo**. A Red Hat machine without root, an Ubuntu laptop,
Debian and WSL all follow the same single path. macOS is the Brewfile's
business; `local/install.sh` exits silently on Darwin. Four layers, in
order, each with its own gate:

1. **`local/manifest`** (gate `local-tools`) — the single-binary tools
   (rg, fd, bat, eza, fzf, zoxide, delta, jq, starship, duf, dust,
   shellcheck, ccache, ninja), each pinned to an exact upstream release
   asset per architecture, installed into `~/.local/bin`. musl-static
   picks wherever they exist, so glibc age does not matter.
2. **`local/prefix.sh`** (gate `local-prefix`) — whole toolchain trees
   under `~/.local/opt/<name>-<ver>` (cmake, the LLVM/clang suite), with
   stable unversioned symlinks in `~/.local/bin` as the only interface —
   the prefix directories never go on PATH. This is the userland
   replacement for apt's `update-alternatives` clang unversioning. The
   LLVM tarball is ~2 GB / ~6 GB installed; `DOTFILES_SKIP_LLVM=1` in
   `~/.localrc` opts out.
3. **nvm** (not gated; `~/.nvm` is the idempotency) — nodejs/npm, already
   lazy-loaded by `zsh/env.zsh`.
4. **`local/build.sh`** (gate `local-build`) — zsh and tmux from source,
   *only* when the system copy is absent or older than the minimum
   (zsh ≥ 5.8, tmux ≥ 3.2a — every targeted distro passes, so existing
   machines never rebuild). Dependencies (pkgconf, ncurses, libevent) are
   built **static** into `~/.local` on demand, so the resulting tmux/zsh
   are self-contained and never need `LD_LIBRARY_PATH`.

**Skip-if-present ladder** (shared, in `local/lib.sh`): our own
`~/.local/bin/<name>` wins and is refreshed only when older than the pin
(never downgraded); an acceptable system copy is kept as-is (the `min`
column of the manifest — existing Ubuntu/RHEL machines re-download
nothing); otherwise the pin is installed.

**Prerequisite contract**: `git curl unzip xz tar python3` (and
`gcc`/`make` for the source-build layer only) are checked and reported,
never installed — the WARN text names the system package; this repo never
runs sudo. `chsh` is likewise out of scope: tmux pins `default-shell`, and
shells launch zsh from PATH, where `~/.local/bin` leads (zshenv).

**xclip** is the one deliberate omission: X11 libraries are not
userland-installable. tmux's copy-command cascade (pbcopy → clip.exe →
xclip → xsel) keeps working with whatever the system provides.

## The fonts topic (Linux terminals)

`fonts/install.sh` (gate `fonts-nerd`) unpacks the JetBrainsMono Nerd
Font Mono TTFs from a pinned ryanoasis/nerd-fonts release into
`~/.local/share/fonts` and registers them with `fc-cache` — userland, no
root. Every private-use-area glyph the configs draw (LazyVim's
lualine/mini.icons, starship's module icons, Claude Code's statusline
symbols) lives in that font; on a stock-fonts machine (DejaVu Sans Mono
and friends) those render as tofu boxes that look like broken plugins
but never are. macOS gets the same font from the Brewfile
(`font-jetbrains-mono-nerd-font`); the installer exits silently on
Darwin.

Selecting the font *in* the terminal emulator stays per-machine state
the repo never touches: the install only makes the family selectable
(GNOME Terminal: uncheck "Use the system fixed-width font", pick
"JetBrainsMono Nerd Font Mono").

## Hash-gates (script/gate.sh)

Slow, side-effectful installers are wrapped in a gate: the sha256 of their
input file is stored as a flat file `~/.local/state/dotfiles/gate-<key>`
after a successful run, and an unchanged input is skipped on the next run.
Gated today: the `Brewfile` (key `brew`), `local/manifest` (`local-tools`),
`local/prefix.sh` (`local-prefix`), `local/build.sh` (`local-build`) and
`fonts/install.sh` (`fonts-nerd` — for these the pins live in the scripts,
so the scripts are the gate inputs); an overlay repo can add its own
gates — see docs/OVERLAY.md.

The gate knows file contents, not script contents: after editing an
installer itself, force a re-run with
`rm -rf "${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"`.

## Machine variance

Everything machine-specific lives outside the repo:

- `~/.localrc` (0600, never committed — see `zsh/localrc.example`): secrets,
  feature flags (`DOTFILES_VCPKG=1`, `DOTFILES_SKIP_VSCODE_EXTENSIONS=1`,
  `DOTFILES_SKIP_LLVM=1`), compiler variance (`CC`/`CXX`).
- `~/.gitconfig.local`: identity (generated on first bootstrap) and
  per-machine git overrides.
- A private overlay repo, if you keep one (see docs/OVERLAY.md): anything
  personal or non-publishable.

Runtime guards (`command -v …`) decide behavior differences at execution
time; `darwin/`/`linux/` subtrees decide them at link time. Nothing else
sniffs the OS.

## zsh plugins

No plugin manager. `zsh/install.sh` clones five plugins (four from the
zsh-users organization plus per-directory-history) as **pinned git clones** into
`~/.local/share/zsh/plugins/` (pins inline in that script — the single place
to bump). A clone at the wrong revision is fetched and re-detached to the pin
automatically. The sources are `[ -f ]`-guarded, so a shell works before
`script/install` has ever run.
