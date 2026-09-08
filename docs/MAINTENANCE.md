# Maintenance

Recipes for everything you will want to change. One rule above all:
**the target files in `$HOME` are symlinks — always edit the source in the
repo**, never the symlinked file (edits through a symlink do land in the
repo, but check `git -C ~/.dotfiles diff` before wondering where a change
came from).

## Add an alias / a shell function / an option

Create a file in `zsh/` (e.g. `zsh/docker.zsh` containing `alias dk=…`).
It is sourced on the next shell. No registration anywhere.

Autoloaded functions go in `functions/` (that directory is on `fpath`);
completions for them are `_name` files next to them.

## Add a dotfile

- targets `$HOME/.foo` → create `topic/foo.symlink`
- targets `~/.config/foo/*` → create `topic/config/foo/*.symlink`
  (a whole config directory can be one `topic/config/foo.symlink` directory)
- targets a nested dot-path like `~/.ssh/config` → `topic/home/.ssh/config.symlink`
- only on one OS → put it under `topic/darwin/` or `topic/linux/`

Then `bin/dot` (or `~/.dotfiles/script/bootstrap`).

## Add a tool (the full topic recipe)

1. `mkdir mytool/`
2. Its dotfiles as `*.symlink` per the rules above.
3. Its shell glue as `*.zsh` (sourced automatically).
4. Optionally `mytool/install.sh` — must be idempotent; if slow, wrap the
   expensive part in a gate:
   `. "$(cd "$(dirname "$0")/.." && pwd -P)/script/gate.sh"`
   `gate mytool input-file && { do_things && gate_done mytool input-file; }`
5. Packages: add the brew formula to `Brewfile` **and** the apt package to
   `apt/packages` (both are hash-gated).
6. Re-run `bin/dot`.

## Bump a pinned zsh plugin

Edit the pin in `zsh/install.sh` (version tag or commit SHA), run
`~/.dotfiles/script/install` — a drifted clone is fetched and re-detached
automatically. That file is the single source for plugin versions.

## Force everything to re-run

Hash-gates compare input files, not scripts. After changing an installer:

```sh
rm -rf "${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"
~/.dotfiles/script/install
```

## Change the compiler / machine flags

`~/.localrc` (never committed):

```sh
export CC=clang CXX=clang++
export DOTFILES_VCPKG=1                  # opt-in: bootstrap vcpkg into ~/vcpkg
export DOTFILES_SKIP_VSCODE_EXTENSIONS=1 # opt-out: skip the public VS Code set
```

## Public vs private

This repo is the **public plumbing**: generic, reusable, no personal data, no
secrets, no hints about specific environments or services. Anything personal
lives in a **private overlay** — a second repo with the same topic model,
applied after this one. The concept, the split criteria, the apply order, the
disjoint-file-set audit and the public extension points are documented in
[docs/OVERLAY.md](OVERLAY.md).

## Before pushing

```sh
gitleaks detect --source ~/.dotfiles -v          # secrets
git -C ~/.dotfiles remote -v                      # github-kilua77 only
```

CI runs gitleaks, shellcheck on every sh/bash script, and a smoke bootstrap
in an isolated fake `$HOME` on every push.

## Troubleshooting

- **A dotfile changed but nothing happened** → it is not a `*.symlink` file,
  or it is in `darwin/`/`linux/` on the wrong OS. Check with
  `~/.dotfiles/script/bootstrap --dry-run`.
- **An installer did not re-run** → its gate: see *Force everything*.
- **A shell file has a syntax error** → `zsh -n <file>`; the loader is
  depth-1 (`*/*.zsh`), nested files are not sourced by design.
- **Something got clobbered** → look in `~/.dotfiles-backup/<stamp>/`.
- **Where did my old config go?** → the pre-rebuild state is preserved in
  the git tags `legacy` (2016) and `chezmoi-v1` (2026 intermediate state).
