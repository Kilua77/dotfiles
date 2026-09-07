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
   others.

`bin/dot` chains the three commands: `git pull --ff-only` (when a remote
exists) → `script/bootstrap "$@"` → `script/install`.

## Hash-gates (script/gate.sh)

Slow, side-effectful installers are wrapped in a gate: the sha256 of their
input file is stored in `~/.local/state/dotfiles/gate-<key>/` after a
successful run, and an unchanged input is skipped on the next run. Gated
today: the `Brewfile` (key `brew`), `apt/packages` (key `apt`), and — in the
private layer — `~/.localrc` for MCP registration (key `claude-mcp`).

The gate knows file contents, not script contents: after editing an
installer itself, force a re-run with
`rm -rf "${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"`.

## Machine variance

Everything machine-specific lives outside the repo:

- `~/.localrc` (0600, never committed — see `zsh/localrc.example`): secrets,
  feature flags (`DOTFILES_VCPKG=1`, `DOTFILES_SKIP_VSCODE_EXTENSIONS=1`),
  compiler variance (`CC`/`CXX`).
- `~/.gitconfig.local`: identity (generated on first bootstrap) and
  per-machine git overrides.
- The private overlay repo (see docs/MAINTENANCE.md): personal tools and
  anything that should not be public.

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
