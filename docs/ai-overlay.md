# The public/private overlay pattern for AI tool config

This repo (public) and a second, private chezmoi repo both manage dotfiles in the
same `$HOME`. The public repo carries the reusable plumbing; the private repo is
an overlay applied on top that carries everything specific to one person.

## Why split

AI tool config splits cleanly in two kinds:

- **Plumbing** — hooks, formatters, example configs, docs. It describes the
  *machine* and is useful to anyone. It belongs in the public repo.
- **Policy** — model routing, provider choices, MCP servers, personal skills,
  prompt persona. It describes *you*: what you pay for, which endpoints you
  trust, how you like answers. It belongs in the private repo.

Publishing policy leaks habits and endpoint names into a public repo; keeping
plumbing private forces everyone to reinvent it. Two repos, one rule.

## How it works

Two disjoint chezmoi sources, both applied to the same `$HOME`:

```sh
# Public repo (default source, ~/.local/share/chezmoi) — applied FIRST.
chezmoi apply

# Private repo — applied SECOND, so private decisions are the final state.
chezmoi --source ~/.local/share/chezmoi-private apply
```

Bootstrap the private repo the same way as the public one:

```sh
chezmoi --source ~/.local/share/chezmoi-private init <your-private-repo-url>
```

A shell alias keeps the second command as short as the first:

```sh
alias dot-private='chezmoi --source ~/.local/share/chezmoi-private'
# usage: dot-private apply | diff | edit | managed | re-add
```

Apply order matters only where the two repos would touch the same file — which
the next rule forbids.

## THE RULE: disjoint file sets

**The public repo must never manage a file the private repo manages.** chezmoi
sources do not know about each other; if both manage a path, the last `apply`
wins and silently clobbers the other. Nothing warns you.

Audit the invariant after adding files to either repo — this must print nothing:

```sh
comm -12 <(chezmoi managed | sort) <(dot-private managed | sort)
```

## What belongs where

| Public repo                                     | Private repo                                             |
| ----------------------------------------------- | -------------------------------------------------------- |
| Generic hooks (`~/.claude/hooks/format-cpp.sh`) | Real `~/.claude/settings.json`                           |
| Example configs (`templates/*.example.json`)    | `~/.claude/CLAUDE.md` persona, `~/.claude/statusline.sh` |
| Docs (this directory)                           | `~/.claude/skills/`, agent definitions                   |
| Tool bootstrap (compilers, formatters)          | MCP registration script (see below)                      |
|                                                 | Editor configs tied to personal licenses/extensions      |

Concrete example: this repo ships `format-cpp.sh` to `~/.claude/hooks/` but does
not activate it, because activating it means writing `~/.claude/settings.json`,
which is private. `templates/claude-settings.example.json` shows the snippet to
copy into the private repo's version of that file.

## MCP servers

Never template `~/.claude.json`. Claude Code rewrites that file itself (MCP
registrations, project history, login state); chezmoi managing it means every
session produces drift.

Register servers with the CLI from a `run_onchange` script *in the private
repo* (a `.tmpl` template, so chezmoi re-runs it whenever `~/.localrc` changes),
reading endpoints and tokens from the environment provided by `~/.localrc`:

```sh
# ~/.local/share/chezmoi-private/run_onchange_register-mcp.sh.tmpl
#!/bin/sh
[ -r "$HOME"/.localrc ] && . "$HOME"/.localrc
[ -n "$EXAMPLE_MCP_URL" ] || exit 0
# checksum: {{ include "~/.localrc" | sha256sum }}
claude mcp add --scope user --transport http example-mcp "$EXAMPLE_MCP_URL"
```

Tokens never enter a source state; they stay in `~/.localrc`, which this public
repo deliberately ignores (see `.chezmoiignore`).

## Never commit, in either repo

- `~/.claude.json` — live app state, see MCP section above.
- `~/.claude/.credentials.json` — secrets.
- `~/.claude/projects/` — session transcripts, unbounded and private.
- `.claude/settings.local.json` — per-project scratch; not dotfiles material.

## Drift: when the app edits its own settings

Claude Code writes to `~/.claude/settings.json` itself (`/config`, `/model`,
plugin toggles). The file on disk then differs from the private source:

1. Inspect: `dot-private diff ~/.claude/settings.json`.
2. Keep the app's change: re-adopt it into the private source —
   `dot-private re-add ~/.claude/settings.json`.
3. Or reject it: `dot-private apply ~/.claude/settings.json`.
4. Or edit at the source: `dot-private edit --apply ~/.claude/settings.json`.

Caveat on `edit`: it opens the *source* file. For a plain file that is the
final content; for a templated file (`.tmpl`) you are editing the template, and
`--apply` renders it immediately — template errors surface at that moment.

Related files: `dot_claude/hooks/format-cpp.sh` (deployed hook),
`templates/claude-settings.example.json` (reference settings, repo-only).
