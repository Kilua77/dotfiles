# Maintenance

Recipe book for the changes you will actually make: goal + exact commands.
Background lives in [ARCHITECTURE.md](ARCHITECTURE.md).

## Add a new dotfile

```sh
chezmoi add ~/.foo            # copies ~/.foo into the source as dot_foo
chezmoi apply                 # no-op here, deploys on new machines
```

Manual alternative (file does not exist yet): create `dot_foo` or
`dot_foo.tmpl` in the repo. Naming rules: `dot_` -> target starts with `.`,
`private_` -> mode 0600, `executable_` -> mode 0755, `.tmpl` -> Go template.
Nested paths work per directory: `dot_config/nvim` -> `~/.config/nvim`.

## Edit a deployed file

```sh
chezmoi edit --apply ~/.zshrc   # edit the SOURCE, then redeploy immediately
```

Warning -- apps that rewrite their own config change the target behind
chezmoi's back:

```sh
chezmoi diff                       # shows the drift (target vs. rendered source)
chezmoi add ~/.config/foo/config   # capture the app's current state as source
```

Template caveat: if the source is a `.tmpl`, `chezmoi add` replaces it with a
literal snapshot and your template logic is lost. Diff first, port the changes
into the template by hand, then `chezmoi apply`.

## Add a Homebrew formula / cask (macOS)

Edit `Brewfile`, then `chezmoi apply`. No extra step: the brew script embeds
`# hash: {{ include "Brewfile" | sha256sum }}`, so editing the Brewfile
changes that hash, which changes the script's rendered content -- exactly what
`run_onchange` keys on. Manual run: `brew bundle --file=Brewfile` (chezmoi
runs scripts with cwd = the source directory, so that also works as-is).

## Add an apt package (Linux)

Edit the `common=(...)` or `dev=(...)` list in
`.chezmoiscripts/run_onchange_after_11-apt-packages.sh.tmpl`, then
`chezmoi apply`; editing the list re-triggers the script. One `apt-get
install` per package on purpose: a package missing on a derivative distro
only WARNs.

## Bump a pinned plugin or Neovim

1. Edit `.chezmoidata/versions.yaml` (the only place versions live).
2. `chezmoi apply`.

zsh plugin archives re-download because their URL changed. Neovim (Linux)
re-runs its script -- but note the skip rule: an existing nvim >= 0.10 is
kept. Force the upgrade with:

```sh
rm -rf ~/.local/opt/nvim-* ~/.local/bin/nvim
chezmoi apply
```

## Change the compiler on one machine

```sh
chezmoi edit-config    # opens ~/.config/chezmoi/chezmoi.toml
# [data] ... compiler = "clang"
chezmoi apply          # re-renders ~/.zshrc with the new CC/CXX exports
```

`name` and `email` change the same way, in the same file.

## Toggle vcpkg / vscode_extensions

```sh
chezmoi edit-config    # flip vcpkg = false / vscode_extensions = false
chezmoi apply
```

Flipping a flag switches the script's rendered branch (full body vs. early
exit), changing its content hash, so it re-runs in the new mode. Disabling
does NOT uninstall anything; `rm -rf ~/vcpkg` is manual, by design.

## Add a new zsh plugin

Three steps:

1. Pin it in `.chezmoidata/versions.yaml`:

   ```yaml
   versions:
     zsh_my_plugin: "v1.2.3"
   ```

2. Declare the archive in `.chezmoiexternal.toml`:

   ```toml
   [".local/share/zsh/plugins/zsh-my-plugin"]
       type = "archive"
       url = "https://github.com/<org>/zsh-my-plugin/archive/refs/tags/{{ .versions.zsh_my_plugin }}.tar.gz"
       exact = true
       stripComponents = 1
       refreshPeriod = "168h"
   ```

3. Source it in `dot_zshrc.tmpl`. Ordering matters: `zsh-syntax-highlighting`
   must be sourced last (except `zsh-history-substring-search`, after it).

Then `chezmoi apply`.

## Add a chezmoi script

Create `.chezmoiscripts/run_<when>_<phase>_<nn>-<name>.sh.tmpl` where
`<when>` is `once_` (per machine) or `onchange_` (content-hash keyed),
`<phase>` is `before_` or `after_` the file-copy step, and `<nn>` slots the
script into the lexical order (table in ARCHITECTURE.md). Rules: the rendered
output must start with `#!` (chezmoi detects scripts by shebang -- keep it
first in every template branch), end with `exit 0`, and WARN-and-continue on
failure. If the script reads an external file, make the dependency explicit on
line 2 with `# hash: {{ include "<file>" | sha256sum }}`; otherwise rely on
plain content hashing, no markers needed.

## Understand why a script re-ran

`run_onchange` compares the sha256 of the script's rendered content against
chezmoi's state database. A re-run means the rendered text changed: a pin
bump, a list edit, or a flag flip that switched a template branch.

```sh
chezmoi apply --verbose      # prints each script as it runs
chezmoi diff                 # file drift only (does not cover scripts)
```

Force everything to re-run once (think twice):

```sh
chezmoi state delete-bucket --bucket=scriptState
chezmoi apply
```

## Troubleshooting

| Symptom | Command |
|---|---|
| "something is off" | `chezmoi doctor` (sanity-checks install + config) |
| target differs from source | `chezmoi diff` |
| what does chezmoi manage? | `chezmoi managed` |
| what is excluded | `chezmoi ignored` |
| preview an apply | `chezmoi apply --dry-run --verbose` |
| reset script run-state | `chezmoi state delete-bucket --bucket=scriptState` |

## Where the AI / private config lives

Nothing AI-related lives in this repo, by design. AI assistant configuration,
its VS Code extensions, and the key variables it reads from `~/.localrc` are
in the private overlay applied on top of this public repo; see
[ai-overlay.md](ai-overlay.md). The contract this repo provides: `~/.zshrc`
sources `~/.localrc` (template in `dot_localrc.example`).
