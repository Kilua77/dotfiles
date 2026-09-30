#!/usr/bin/env bash
#
# local/prefix.sh — toolchain prefixes for Linux: whole versioned trees
# under ~/.local/opt/<name>-<ver>, with stable unversioned symlinks in
# ~/.local/bin as the only interface (the prefix directories themselves
# never go on PATH). Same mechanics as nvim/install.sh, applied to the
# two toolchains that are trees rather than single binaries:
#
#   cmake 4.4.3  -> ~/.local/opt/cmake-4.4.3   symlinks: cmake cpack ctest
#   LLVM  18.1.8 -> ~/.local/opt/llvm-18.1.8   symlinks: clang clang++
#                                                   clangd clang-format
#                                                   clang-tidy lld ld.lld
#
# The LLVM tarball replaces what build-essential + the clang-* packages
# used to provide: one download carrying the compiler, the language
# server, the linters and the linker. It is BIG (~1-2 GB download, ~5 GB
# extracted) — skip it on disk-tight machines with DOTFILES_SKIP_LLVM=1
# in ~/.localrc.
#
# WHY 18.1.8 and not a current release: the newer official tarballs
# (LLVM-<v>-Linux-X64, everything since ~19) are built on a newer
# baseline and require GLIBCXX_3.4.30 (GCC 12's libstdc++) and
# GLIBC_2.34 — the RHEL 9 target only provides GLIBCXX_3.4.29 (GCC 11).
# Measured on the LLVM 23.1.2 binaries: GLIBC floor 2.34, GLIBCXX floor
# 3.4.30. The 18.1.8 ubuntu-18.04 build (GLIBC 2.27 / GLIBCXX 3.4.25)
# runs everywhere from RHEL 8 up. Revisit the pin when RHEL 10 (GCC 14
# base) becomes the floor — and note Ubuntu 24.04 / RHEL 10 machines
# with a system clang suite >= 16 never download this at all.
#
# Skip-if-present (see local/lib.sh):
#   - our symlink in ~/.local/bin wins; the prefix is refreshed only when
#     it is older than the pin (previous ~/.local/opt/<name>-* dirs are
#     left in place, remove them by hand once the new pin works)
#   - cmake: a system cmake >= CMAKE_MIN (3.27) is kept
#   - LLVM: all-or-nothing on clang — a system set with clang, clangd,
#     clang-format AND clang-tidy all >= LLVM_MIN (16) is kept; anything
#     less installs the whole pinned prefix (a half system/half local
#     toolchain is worse than either)
#
# Gate: local-prefix, over this file itself — the pins live here, so
# editing one changes the hash and re-runs the layer.
#
# Failure policy: WARN and move on; a partial download never replaces a
# working prefix (rm of the destination happens only after extraction).

# shellcheck disable=SC2153    # LOCAL_BIN/LOCAL_OPT are set by lib.sh below
set -u

if [ "$(uname -s)" = "Darwin" ]; then
    exit 0
fi

LOCAL_DIR="$(cd "$(dirname "$0")" && pwd -P)"
# shellcheck source=/dev/null  # lib.sh is linted on its own
. "$LOCAL_DIR/lib.sh"
# shellcheck source=/dev/null  # gate.sh is linted on its own
. "$LOCAL_DIR/../script/gate.sh"

# Machine flags live in ~/.localrc — never committed.
# shellcheck source=/dev/null  # user-local, by definition not in this repo
[ -f "$HOME/.localrc" ] && . "$HOME/.localrc"

# --- Resumable download (the LLVM tarball is ~2 GB; plain fetch() would
# restart from zero on a flaky link) ------------------------------------------

fetch_big() {  # fetch_big <url> <dest>
    attempt=1
    while [ "$attempt" -le 3 ]; do
        if [ -f "$2" ]; then
            curl -fsSL -C - --connect-timeout 15 "$1" -o "$2" && return 0
        else
            curl -fsSL --connect-timeout 15 "$1" -o "$2" && return 0
        fi
        attempt=$((attempt + 1))
        sleep 2
    done
    echo "WARN: local: download failed (3 attempts): $1"
    return 1
}

# --- Install one prefix tarball ------------------------------------------------
# prefix_install <name> <ver> <url> <asset> <extracted-root> <bin...>
# Example: prefix_install cmake 4.4.3 <url> cmake.tgz cmake-4.4.3-linux-x86_64 cmake cpack ctest

prefix_install() {
    name="$1" ver="$2" url="$3" asset="$4" root="$5"
    nbins=$(($# - 5))
    shift 5
    dest="$LOCAL_OPT/$name-$ver"
    tmp="$(mktemp -d 2>/dev/null)" || {
        echo "WARN: local: $name: mktemp failed"
        return 1
    }
    echo "local: $name: downloading ${asset} (this can take a while)"
    if ! fetch_big "$url" "$tmp/$asset"; then
        rm -rf "$tmp"
        return 1
    fi
    if ! extract "$tmp/$asset" "$tmp/x"; then
        echo "WARN: local: $name: extraction failed"
        rm -rf "$tmp"
        return 1
    fi
    if [ ! -d "$tmp/x/$root" ]; then
        # Upstream has renamed the top-level dir between releases; fall
        # back to a single-directory archive layout before giving up.
        root="$(find "$tmp/x" -mindepth 1 -maxdepth 1 -type d | head -1)"
    fi
    if [ -z "${root:-}" ] || [ ! -d "$tmp/x/$root" ]; then
        echo "WARN: local: $name: could not find the tree inside the archive"
        rm -rf "$tmp"
        return 1
    fi
    # Only now, with a complete extracted tree, is the old prefix replaced.
    rm -rf "$dest"
    mkdir -p "$LOCAL_OPT" "$LOCAL_BIN"
    if ! mv "$tmp/x/$root" "$dest"; then
        echo "WARN: local: $name: could not move tree into $LOCAL_OPT"
        rm -rf "$tmp"
        return 1
    fi
    for bin in "$@"; do
        if [ -e "$dest/bin/$bin" ]; then
            ln -sfn "$dest/bin/$bin" "$LOCAL_BIN/$bin"
        else
            echo "WARN: local: $name: no '$bin' in the prefix (symlink skipped)"
        fi
    done
    rm -rf "$tmp"
    echo "local: $name: installed $ver -> $dest (+$nbins symlinks)"
    return 0
}

# --- The layer ------------------------------------------------------------------

run_prefix() {
    arch="$(lb_arch)" || {
        echo "WARN: local: unsupported architecture $(uname -m) — prefixes skipped"
        return 1
    }
    failed=0

    # cmake ------------------------------------------------------------------
    CMAKE_VER="4.4.3"
    CMAKE_MIN="3.27"
    case "$arch" in
        x86_64) cmake_asset="cmake-4.4.3-linux-x86_64.tar.gz" ;;
        *) cmake_asset="cmake-4.4.3-linux-aarch64.tar.gz" ;;
    esac
    if [ -x "$LOCAL_BIN/cmake" ] && ver_ge "$(bin_version "$LOCAL_BIN/cmake")" "$CMAKE_VER"; then
        echo "local: cmake: $(bin_version "$LOCAL_BIN/cmake") already installed"
    elif command -v cmake >/dev/null 2>&1 \
        && ver_ge "$(bin_version "$(command -v cmake)")" "$CMAKE_MIN"; then
        echo "local: cmake: system $(bin_version "$(command -v cmake)") kept"
    else
        prefix_install cmake "$CMAKE_VER" \
            "https://github.com/Kitware/CMake/releases/download/v$CMAKE_VER/$cmake_asset" \
            "$cmake_asset" "cmake-$CMAKE_VER-linux-$arch" cmake cpack ctest \
            || failed=1
    fi

    # LLVM / clang suite -----------------------------------------------------
    if [ "${DOTFILES_SKIP_LLVM:-0}" = "1" ]; then
        echo 'local: llvm: skipped (DOTFILES_SKIP_LLVM=1)'
    else
        LLVM_VER="18.1.8"
        LLVM_MIN="16"
        case "$arch" in
            x86_64) llvm_asset="clang+llvm-$LLVM_VER-x86_64-linux-gnu-ubuntu-18.04.tar.xz" ;;
            *) llvm_asset="clang+llvm-$LLVM_VER-aarch64-linux-gnu.tar.xz" ;;
        esac
        llvm_root="${llvm_asset%.tar.xz}"
        llvm_bins="clang clang++ clangd clang-format clang-tidy lld ld.lld"
        if [ -x "$LOCAL_BIN/clang" ] && ver_ge "$(bin_version "$LOCAL_BIN/clang")" "$LLVM_VER"; then
            echo "local: llvm: $(bin_version "$LOCAL_BIN/clang") already installed"
        else
            # All-or-nothing: every tool of the suite must clear LLVM_MIN for
            # the system toolchain to be kept (see header).
            system_ok=1
            for t in $llvm_bins; do
                if ! command -v "$t" >/dev/null 2>&1 \
                    || ! ver_ge "$(bin_version "$(command -v "$t")")" "$LLVM_MIN"; then
                    system_ok=0
                    break
                fi
            done
            if [ "$system_ok" = 1 ]; then
                echo "local: llvm: system $(bin_version "$(command -v clang)") kept (full suite >= $LLVM_MIN)"
            else
                # shellcheck disable=SC2086  # llvm_bins is a deliberate word list
                prefix_install llvm "$LLVM_VER" \
                    "https://github.com/llvm/llvm-project/releases/download/llvmorg-$LLVM_VER/$llvm_asset" \
                    "$llvm_asset" "$llvm_root" $llvm_bins \
                    || failed=1
            fi
        fi
    fi

    [ "$failed" -eq 0 ]
}

if gate local-prefix "$LOCAL_DIR/prefix.sh"; then
    if run_prefix; then
        gate_done local-prefix "$LOCAL_DIR/prefix.sh"
    else
        echo 'WARN: local: a prefix install failed — it retries on the next run'
    fi
else
    echo 'local: prefixes unchanged since last success, skipped'
fi

exit 0
