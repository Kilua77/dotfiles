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
# package missing on a derivative distro must never abort the run. But
# three consecutive failures with the SAME first output line mean a
# systemic cause (no sudo password, a held dpkg lock, a dead mirror), so
# the loop stops early and prints the error once with its fix instead of
# once per package. The gate is only recorded when every package
# succeeded, so failures are retried on the next run.

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

# One apt at a time: two concurrent runs (two terminals, dot twice) would
# silently wait on the dpkg lock forever. Hold an flock; a second instance
# exits politely instead.
mkdir -p "$GATE_STATE"
exec 9>"$GATE_STATE/apt.lock"
if ! flock -n 9; then
  echo "apt: another install is running, skipping (wait for it or retry)"
  exit 0
fi

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
failed_names=""
sig=""       # first line of the last failure's output
streak=0     # consecutive failures sharing that signature
while IFS= read -r p || [ -n "$p" ]; do
  case "$p" in
    ''|'#'*) continue ;;
  esac
  if dpkg -s "$p" >/dev/null 2>&1; then
    echo "apt: $p ok (already installed)"
    ok=$((ok + 1))
    continue
  fi
  # Progress line BEFORE the (possibly long) install, then capture apt's
  # output so a failure can explain itself — a silent install of a large
  # package is indistinguishable from a hang. Timeouts make a dead mirror
  # fail fast instead of hanging forever.
  #
  # DEBIAN_FRONTEND goes AFTER sudo (via env): sudo's env_reset strips a
  # prefix assignment, and without it a post-install hook like needrestart
  # prompts through debconf (frontend: Dialog here) on stdin/stdout — the
  # captured pipe and this loop's redirected stdin — and hangs forever.
  # </dev/null makes sure no hook can ever read the packages file instead.
  printf 'apt: installing %s ... ' "$p"
  if out="$("$SUDO" env DEBIAN_FRONTEND=noninteractive apt-get install -y \
        -o Acquire::http::Timeout=30 -o Acquire::https::Timeout=30 \
        -o Acquire::Retries=2 "$p" </dev/null 2>&1)"; then
    echo "ok"
    ok=$((ok + 1))
    streak=0
  else
    echo "FAILED (last lines below)"
    printf '%s\n' "$out" | tail -n 4
    failed=$((failed + 1))
    failed_names="$failed_names $p"

    this_sig="$(printf '%s\n' "$out" | head -n 1)"
    [ -n "$this_sig" ] || this_sig='(no output)'
    if [ "$this_sig" = "$sig" ]; then
      streak=$((streak + 1))
    else
      sig="$this_sig"
      streak=1
    fi

    # Three consecutive failures with the identical first line: the cause is
    # systemic (credentials, lock, network), not package-specific. Print it
    # once with a fix instead of once per remaining package, then stop —
    # nothing later in the list can succeed anyway.
    if [ "$streak" -ge 3 ]; then
      echo "apt: stopping — the same error just failed $streak packages in a row:"
      echo "apt:   $sig"
      case "$sig" in
        *'sudo: a password is required'* | *'sudo: a terminal is required'*)
          echo 'apt: cause: sudo cannot ask for a password in this context'
          echo 'apt: fix:   re-run script/install from an interactive terminal'
          echo 'apt:        (or configure passwordless sudo for apt-get)'
          ;;
        *'Could not get lock'* | *'frontend lock'* | *'dpkg lock'*)
          echo 'apt: cause: another apt/dpkg process holds the lock'
          echo "apt: fix:   wait for it (pgrep -af 'apt|dpkg'), close other installers, re-run"
          ;;
        *)
          echo 'apt: cause: (unrecognized) — resolve the error above, then re-run;'
          echo 'apt:        the remaining packages retry (the gate is not recorded)'
          ;;
      esac
      echo 'apt: skipping the remaining packages in this run'
      break
    fi
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
  echo "apt: failed packages:${failed_names}"
fi

exit 0
