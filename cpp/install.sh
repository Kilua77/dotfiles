#!/bin/sh
#
# cpp/install.sh — optional vcpkg bootstrap (C++ dependency manager).
#
# Ported from the chezmoi-era run_onchange_after_40-vcpkg-bootstrap.sh.tmpl:
# the chezmoi feature flag is replaced by DOTFILES_VCPKG=1 in ~/.localrc
# (opt-in), and the run_onchange hash gate is not needed — the ~/vcpkg
# existence check below IS the idempotency mechanism, so re-runs are cheap.
#
# Failure policy: every step WARNs and exits 0; this must never break an
# install run.

set -u

# Machine flags (including DOTFILES_VCPKG) live in ~/.localrc — never committed.
# shellcheck source=/dev/null  # user-local, by definition not in this repo
[ -f "$HOME/.localrc" ] && . "$HOME/.localrc"

if [ "${DOTFILES_VCPKG:-0}" != "1" ]; then
  echo "cpp: vcpkg bootstrap not requested (set DOTFILES_VCPKG=1 in ~/.localrc to opt in)"
  exit 0
fi

if [ -d "$HOME/vcpkg" ]; then
  echo "vcpkg: ~/vcpkg already present, bootstrap skipped"
  exit 0
fi

command -v git >/dev/null 2>&1 || {
  echo "WARN: git not found, skipping vcpkg bootstrap"
  exit 0
}
command -v curl >/dev/null 2>&1 || {
  echo "WARN: curl not found (bootstrap downloads the vcpkg binary), skipping"
  exit 0
}

echo "vcpkg: shallow-cloning to ~/vcpkg"
if ! git clone --depth 1 https://github.com/microsoft/vcpkg.git "$HOME/vcpkg"; then
  echo "WARN: vcpkg clone failed -- see https://github.com/microsoft/vcpkg"
  exit 0
fi

# bootstrap-vcpkg.sh takes the same arguments on Linux and macOS.
echo "vcpkg: running bootstrap (downloads the prebuilt vcpkg binary)"
if ! (cd "$HOME/vcpkg" && ./bootstrap-vcpkg.sh -disableMetrics); then
  echo "WARN: vcpkg bootstrap failed -- run ~/vcpkg/bootstrap-vcpkg.sh by hand"
  exit 0
fi

echo "vcpkg: ready. Export VCPKG_ROOT=\"$HOME/vcpkg\" for toolchains, e.g.:"
echo "vcpkg:   cmake -B build -DCMAKE_TOOLCHAIN_FILE=$HOME/vcpkg/scripts/buildsystems/vcpkg.cmake"

exit 0
