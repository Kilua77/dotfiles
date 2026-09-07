#!/usr/bin/env bash
#
# gate.sh — sourced (not run) by script/install and by installers that need it.
#
# Hash-gate: skip a slow installer when its input file has not changed since
# the last successful run. This replaces per-manager "run on change" state.
#
#   gate <key> <file>     returns 0 when the installer SHOULD run, 1 to skip
#   gate_done <key> <file>  records success (call after the installer succeeds)
#
# To force everything to re-run: rm -rf "${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"

# shellcheck disable=SC2034  # GATE_STATE is set here for installers that source this file
GATE_STATE="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"

_sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | cut -d' ' -f1
  else
    shasum -a 256 "$1" | cut -d' ' -f1
  fi
}

gate() {
  key="$1" file="$2"
  [ -f "$file" ] || return 0
  state_file="$GATE_STATE/gate-$key"
  [ -f "$state_file" ] || return 0
  [ "$(_sha256 "$file")" = "$(cat "$state_file")" ] && return 1
  return 0
}

gate_done() {
  key="$1" file="$2"
  mkdir -p "$GATE_STATE"
  _sha256 "$file" > "$GATE_STATE/gate-$key"
}
