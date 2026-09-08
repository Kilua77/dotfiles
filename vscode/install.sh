#!/usr/bin/env bash
#
# vscode/install.sh — install the generic VS Code extension set (C/C++
# toolchain, Qt, editing helpers). Deliberately NO AI extensions: those are
# installed by the private overlay, never by this public repo.
#
# Ported from the chezmoi-era run_onchange_after_20-vscode-extensions.sh.tmpl:
# the chezmoi feature flag is replaced by DOTFILES_SKIP_VSCODE_EXTENSIONS=1
# in ~/.localrc (opt-out), and the run_onchange gate is not needed — the
# installed list is snapshotted once below, so re-runs only touch missing
# extensions.
#
# Failure policy: per-extension failures WARN and continue.

set -u

# Machine flags live in ~/.localrc — never committed.
# shellcheck source=/dev/null  # user-local, by definition not in this repo
[ -f "$HOME/.localrc" ] && . "$HOME/.localrc"

if [ "${DOTFILES_SKIP_VSCODE_EXTENSIONS:-0}" = "1" ]; then
  echo "vscode: extension install skipped (DOTFILES_SKIP_VSCODE_EXTENSIONS=1)"
  exit 0
fi

# One WARN for the whole run if the CLI is missing (common on servers/CI).
if ! command -v code >/dev/null 2>&1; then
  echo "WARN: 'code' CLI not found -- install VS Code (macOS cask in the Brewfile), then re-run: script/install"
  exit 0
fi

# The CLI can exist but be unusable (typically a remote/server session whose
# IPC socket is gone). A failed listing must not read as "nothing installed"
# — that would try every extension and WARN once per extension.
if ! installed="$(code --list-extensions 2>/dev/null)"; then
  echo "WARN: 'code' CLI not usable right now (VS Code session/server not reachable?)"
  echo "WARN: extension sync skipped -- re-run script/install once VS Code is up"
  exit 0
fi

extensions=(
  # C/C++ toolchain
  llvm-vs-code-extensions.vscode-clangd
  ms-vscode.cmake-tools
  ms-vscode.cpptools-extension-pack
  # Qt
  theqtcompany.qt-core
  theqtcompany.qt-cpp
  theqtcompany.qt-qml
  theqtcompany.qt-ui
  # Editing and navigation
  eamodio.gitlens
  alefragnani.bookmarks
  vscodevim.vim
  # Remotes and containers
  ms-vscode-remote.remote-ssh
  ms-vscode-remote.remote-containers
  ms-azuretools.vscode-docker
  # Python
  ms-python.python
  ms-python.vscode-pylance
  # Markup and hygiene
  davidanson.vscode-markdownlint
  redhat.vscode-yaml
  streetsidesoftware.code-spell-checker
)

# `installed` was snapshotted once above (the usability check); re-runs only
# touch missing extensions, keeping a fully-provisioned machine off the
# marketplace entirely (`code --install-extension` is idempotent anyway).
for ext in "${extensions[@]}"; do
  if printf '%s\n' "$installed" | grep -Fixq "$ext"; then
    echo "vscode: already installed ${ext}"
    continue
  fi
  if code --install-extension "$ext" >/dev/null 2>&1; then
    echo "vscode: ok ${ext}"
  else
    echo "WARN: could not install ${ext}"
  fi
done

exit 0
