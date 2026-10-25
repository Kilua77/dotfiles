# Layers — the private overlay contract

This repository is the **engine**: it owns every mechanism (linking, install,
adopt, doctor, audit). A **layer** is a private git repository that owns
**policy** — which files, which tools, which Claude configuration — for one
context of your life (personal, work, …). The engine knows the layer format,
so installing a machine is: clone the engine, point it at layer URLs, run one
command.

`docs/OVERLAY.md` describes the older two-repo manual overlay; this contract
generalizes it. Everything below is enforced or exercised by
`script/tests/layers-fixture` in CI.

## The stack

Layer 0 is always the engine repository itself (`public`). The remaining
layers are the lines of the machine-local registry, in file order:

```
${XDG_CONFIG_HOME:-~/.config}/dotfiles/layers     # one per line:
<name> TAB <url-or-path> TAB <clone-path>
```

Which layers a machine runs is machine variance: the registry never enters a
repository. `script/layers` (`list` / `add` / `remove` / `paths`) is its only
writer besides your editor. A work machine registers only the work layer —
isolation is by clone, backed by GitHub private-repo access control.

## What a conforming layer contains

| Path | Status | Meaning |
|---|---|---|
| `layer.json` | must | `{"contract": 1, "name": "personal"}` — `name` is `[a-z][a-z0-9-]*`, unique in the stack; it prefixes gate keys, doctor output and audit labels. The engine refuses a contract version newer than it supports. |
| `<topic>/…​.symlink` | may | Topics, linked by the engine's rules R1–R4 exactly as this repo's own topics (same `script/bootstrap`, invoked with `--root`). |
| `<topic>/install.sh` | may | Run by the engine's install walker, alphabetical, cwd = topic dir, `$LAYER_ROOT` exported; a failure WARNs and does not stop the others. |
| `<topic>/check.sh` | may | Doctor hook: prints `ok:` / `TODO:` / `note:` lines, always exits 0, cwd = topic dir, `$LAYER_ROOT` exported. |
| `claude/manifest.json` | may | Declarative Claude management (MCP servers, plugins, marketplaces) — see below. |
| `claude/home/.claude/settings.json` | may | Settings template policy-merged into `~/.claude/settings.json`. **At most one applied layer may ship one.** |
| `Brewfile` | may | `brew bundle` on it, hash-gated under key `<name>/brew`. |
| `script/` | must not | The engine owns mechanism. If present (pre-contract leftover) the engine ignores it and doctor flags it. |

Installers needing the hash gate source the engine's copy:

```sh
# shellcheck source=/dev/null
. "${LAYER_ROOT_ENGINE:-$HOME/.dotfiles}/script/gate.sh"
```

## Hard rules for N layers

- **Disjoint `$HOME` targets, pairwise.** Two layers may not resolve to the
  same link target; `script/audit` must print nothing.
- **Unique MCP server names** across applied layer manifests.
- **One settings-template owner** per machine (later applies would silently
  win the policy keys — the contract makes that impossible instead).
- **Gate keys are namespaced** `<layer>/<key>`; the engine's own historical
  unprefixed keys are untouched.
- **No secrets, ever.** Endpoints and keys are `~/.localrc` variables,
  referenced by name (`"url": "env:NOTION_MCP_URL"`), never by value.
  A layer remote must be a private repository.

## Fresh machine, one command

```sh
git clone <engine-url> ~/.dotfiles
~/.dotfiles/script/setup --layer <private-layer-url>
```

`setup` clones and registers the layer, then applies the whole stack in
order: adopt → link → install per layer, doctor at the end. A machine that
needs several layers passes several `--layer` flags (order = stack order).

## Claude manifest (`claude/manifest.json`)

Declarations are converged by `script/claude-sync` (run automatically by the
install walker when a manifest exists). The effective set is the **union of
all applied layers' manifests**, filtered by machine selection from
`~/.localrc`: `DOTFILES_MCP_SERVERS` (subset — an absent name is deselected)
and `DOTFILES_SKIP_PLUGINS` (declared plugin disabled, never uninstalled).

```json
{
  "mcp": {
    "notion": { "transport": "http", "url": "env:NOTION_MCP_URL" },
    "chrome-devtools": { "transport": "stdio", "mode": "manual" }
  },
  "marketplaces": { "mem0-plugins": { "source": "mem0ai/mem0-plugins" } },
  "plugins": { "mem0@mem0-plugins": { "enabled": true } }
}
```

- `url` accepts only `env:VAR` references; stdio servers are declared
  `"mode": "manual"` — verified by doctor, never touched by scripts.
- Plugins: missing → installed; `enabled` enforced via enable/disable;
  live state read from `claude plugin list --json`. An enabled-but-undeclared
  plugin is a doctor note; `claude-sync --prune` disables it (never
  uninstalls).

## Why no third-party manager

| Tool | Verdict | Why |
|---|---|---|
| [kasetto](https://github.com/pivoshenko/kasetto) | rejected | new runtime dependency + a second config brain beside bootstrap/adopt/doctor; no plugin management |
| [skillshare](https://github.com/runkids/skillshare) | rejected | skills only — plugins explicitly do not travel; git-sync model duplicates bootstrap |
| [atmos](https://github.com/cloudposse/atmos) | rejected | DevOps-grade weight, absurd for a personal laptop |
| skills.sh | rejected | skills catalog only |
| chezmoi / yadm / stow | rejected | abandoned here in 2026-09; templating is against the no-manager philosophy |
| [9router](https://github.com/decolua/9router) | out of scope | inference gateway (fallback, combos, token compression) — manages neither skills, MCP nor plugins |

The converger is ~bash + `jq` + the `claude mcp` / `claude plugin` CLIs,
which is the whole point: "no dependencies beyond git and a shell".
