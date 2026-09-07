#!/bin/sh
#
# apt/install.sh — install the Linux (apt) packages listed in ./packages.
#
# Ported from the chezmoi-era run_onchange_after_11-apt-packages.sh.tmpl:
# the run_onchange hash gate is replaced by script/gate.sh keyed on the
# packages file — edit the list and script/install re-runs this installer.
# apt is the tested baseline; the guard below makes this a silent no-op on
# non-apt systems (macOS uses Homebrew, other distros are untested).
#
# Failure policy: individual package failures WARN and continue — one
# package missing on a derivative distro must never abort the run. The
# gate is only recorded when every package succeeded, so failures are
# retried on the next run.

set -u

# No apt -> not a supported system for this script; exit silently.
command -v apt-get >/dev/null 2>&1 || exit 0

TOPIC_DIR="$(cd "$(dirname "$0")" && pwd -P)"
PACKAGES="$TOPIC_DIR/packages"

[ -f "$PACKAGES" ] || {
  echo "WARN: apt/install.sh: $PACKAGES not found, nothing to install"
  exit 0
}

# shellcheck source=/dev/null  # gate.sh is linted on its own
. "$(cd "$TOPIC_DIR/.." && pwd -P)/script/gate.sh"

# Skip when the package list is unchanged since the last fully successful run.
if ! gate apt "$PACKAGES"; then
  echo "apt: package list unchanged, skipping"
  exit 0
fi

# Elevation: prefer sudo; run without it when we already are root
# ("passwordless root"). `sudo -n true` is not a reliable am-I-root probe on
# every system, so the uid check is used instead. With SUDO="" the quoted
# "$SUDO" expands to nothing and the command runs directly.
if [ "$(id -u)" -eq 0 ]; then
  SUDO=""
else
  SUDO="sudo"
fi

# --- Package index ----------------------------------------------------------

"$SUDO" apt-get update -qq \
  || echo "WARN: apt-get update failed, continuing with the cached index"

# --- Install loop -------------------------------------------------------------
# One apt-get invocation per package (not one big install): a package missing
# from the distro must not abort the remaining installs. `dpkg -s` first
# keeps re-runs fast (no apt call for anything already present).

ok=0
failed=0
while IFS= read -r p || [ -n "$p" ]; do
  case "$p" in
    ''|'#'*) continue ;;
  esac
  if dpkg -s "$p" >/dev/null 2>&1; then
    echo "apt: $p ok (already installed)"
    ok=$((ok + 1))
    continue
  fi
  if "$SUDO" apt-get install -y "$p" >/dev/null 2>&1; then
    echo "apt: $p ok"
    ok=$((ok + 1))
  else
    echo "WARN: $p not installed"
    failed=$((failed + 1))
  fi
done < "$PACKAGES"

# --- Debian-isms --------------------------------------------------------------
# Debian often ships only versioned binaries (clangd-17, clang-format-17,
# clang-tidy-17, ...). When the unversioned name is missing, register it via
# update-alternatives. /usr/local/bin is used as the master link so we never
# fight Debian's own alternatives under /usr/bin (and /usr/local/bin wins in
# the default PATH). Entirely best effort: failures are ignored.

register_alt() {
  _name="$1" _candidate="$2"
  "$SUDO" update-alternatives --install "/usr/local/bin/$_name" "$_name" "$_candidate" 100 || true
}

# register_unversioned <tool> — first hit among clang* <tool>-19/18/17 wins.
register_unversioned() {
  _tool="$1"
  command -v "$_tool" >/dev/null 2>&1 && return 0
  for _v in 19 18 17; do
    if command -v "${_tool}-${_v}" >/dev/null 2>&1; then
      register_alt "$_tool" "$(command -v "${_tool}-${_v}")"
      break
    fi
  done
}

register_unversioned clangd
register_unversioned clang-format
register_unversioned clang-tidy

# --- Gate ----------------------------------------------------------------------

if [ "$failed" -eq 0 ]; then
  gate_done apt "$PACKAGES"
  echo "apt: $ok package(s) present/installed"
else
  echo "apt: $ok ok, $failed failed -- gate not recorded, failures retry on the next run"
fi

exit 0
