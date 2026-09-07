#!/bin/sh
# nvim/install.sh — make sure a usable Neovim (>= 0.10) exists.
#
# Policy:
#   - macOS: Neovim comes from Homebrew (see the brew topic); exit silently.
#   - Any machine that already has nvim >= 0.10: keep it, exit 0.
#   - Otherwise (non-macOS only): download the pinned official tarball to
#     ~/.local/opt/nvim-<ver> and symlink ~/.local/bin/nvim to it.
#
# Bumping the pin: update NVIM_TAG and NVIM_VER below, then re-run this
# script (or script/bootstrap). NOTE the skip rule above: an existing nvim
# >= 0.10 is always kept; to force an upgrade, remove ~/.local/opt/nvim-*
# and ~/.local/bin/nvim first.
#
# Failure policy: every failure path WARNs and exits 0 — bootstrap must not
# die on an offline or exotic machine.

set -u

# Version pin. Bump both together (tag is the GitHub release, ver the bare
# number used in the install directory; the tarball itself is unversioned,
# named nvim-linux-<arch>.tar.gz since 0.10).
NVIM_TAG="v0.12.5"
NVIM_VER="0.12.5"

# --- macOS: Homebrew owns Neovim here ----------------------------------------

if [ "$(uname -s)" = "Darwin" ]; then
    exit 0
fi

# --- Architecture (official tarballs are published per-arch) -----------------

case "$(uname -m)" in
    x86_64) arch="x86_64" ;;
    aarch64 | arm64) arch="arm64" ;;
    *)
        echo "WARN: unsupported architecture $(uname -m), skipping Neovim install"
        exit 0
        ;;
esac

# --- Skip if the existing Neovim is new enough -------------------------------

if command -v nvim >/dev/null 2>&1; then
    # First line looks like: NVIM v0.9.5
    ver_line="$(nvim --version | head -1)"
    ver="${ver_line#*v}"      # 0.9.5
    major="${ver%%.*}"        # 0
    minor="${ver#*.}"         # 9.5 -> 9 after the next strip
    minor="${minor%%.*}"
    if [ "${major:-0}" -gt 0 ] || [ "${minor:-0}" -ge 10 ]; then
        echo "nvim: existing ${major:-0}.${minor:-0} is >= 0.10, keeping it"
        exit 0
    fi
    echo "nvim: existing ${major:-0}.${minor:-0} is older than 0.10, installing pinned ${NVIM_VER}"
fi

# --- Download and install ----------------------------------------------------

command -v curl >/dev/null 2>&1 || {
    echo "WARN: curl missing, skipping Neovim install"
    exit 0
}

url="https://github.com/neovim/neovim/releases/download/${NVIM_TAG}/nvim-linux-${arch}.tar.gz"
dest="$HOME/.local/opt/nvim-${NVIM_VER}"
tmp="$(mktemp -d)" || {
    echo "WARN: mktemp failed, skipping Neovim install"
    exit 0
}

echo "nvim: downloading ${url}"
if ! curl -fL "$url" -o "$tmp/nvim.tar.gz"; then
    echo "WARN: download failed, skipping Neovim install"
    rm -rf "$tmp"
    exit 0
fi

if ! tar -xzf "$tmp/nvim.tar.gz" -C "$tmp"; then
    echo "WARN: extraction failed, skipping Neovim install"
    rm -rf "$tmp"
    exit 0
fi

# The tarball extracts to nvim-linux-<arch>/; move it to a versioned directory
# so successive pins can coexist, then (re)point a stable symlink at it.
rm -rf "$dest"
mkdir -p "$HOME/.local/opt" "$HOME/.local/bin"
if mv "$tmp"/nvim-linux-* "$dest"; then
    ln -sfn "$dest/bin/nvim" "$HOME/.local/bin/nvim"
    echo "nvim: installed ${NVIM_VER} -> ${dest}"
    echo "nvim: symlinked ~/.local/bin/nvim (make sure ~/.local/bin is on PATH)"
else
    echo "WARN: install step failed, skipping Neovim install"
    rm -rf "$dest"
fi

rm -rf "$tmp"
exit 0
