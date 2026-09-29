#!/usr/bin/env bash
#
# local/install.sh — the Linux userland tool layer. Everything this repo
# delivers on Linux lands under ~/.local (bin/, opt/), pinned to upstream
# release tarballs or guarded source builds. No apt, no dnf, no sudo: a
# Red Hat machine without root, an Ubuntu laptop, Debian and WSL all
# follow this single path. macOS: the Brewfile owns these tools — exit.
#
# Layers (each with its own gate key, run in this order):
#   manifest   local/manifest   single-binary tarballs  -> ~/.local/bin
#   prefix     local/prefix.sh  cmake + LLVM toolchains -> ~/.local/opt
#   nvm        here             nodejs/npm (zsh/env.zsh lazy-loads it)
#   build      local/build.sh   zsh / tmux from source, only when the
#                                system copy is absent or too old
#
# Prerequisites are CHECKED and reported, never installed: git, curl,
# unzip, xz, tar, python3 (plus gcc/clang and make for the source-build
# layer only). The WARN text names the system package — that hint is the
# only place sudo is ever mentioned.
#
# xclip is deliberately NOT installed (needs X11 libs, not userland-
# installable): tmux's copy-command cascade (pbcopy -> clip.exe -> xclip
# -> xsel) keeps working with whatever the machine already has.
#
# Failure policy: every failure path WARNs and moves on — install must
# not die on an offline machine (script/install counts the WARNs).

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

# --- Prerequisites: checked, reported, never installed ------------------------

check_prereqs() {
    for p in git curl unzip xz tar gzip python3; do
        command -v "$p" >/dev/null 2>&1 && continue
        echo "WARN: local: prerequisite '$p' missing — install it system-wide (sudo dnf install $p / sudo apt-get install $p)"
    done
    # A compiler and make only matter for the source-build layer below;
    # the tarball layers run fine without either.
    if ! command -v gcc >/dev/null 2>&1 && ! command -v clang >/dev/null 2>&1; then
        echo "WARN: local: no compiler (gcc/clang) — source builds (zsh/tmux) will be skipped"
    fi
    command -v make >/dev/null 2>&1 || echo "WARN: local: make missing — source builds (zsh/tmux) will be skipped"
    return 0
}

# --- Layer 1: pinned single-binary tarballs (local/manifest) -------------------

run_manifest() {
    arch="$(lb_arch)" || {
        echo "WARN: local: unsupported architecture $(uname -m) — tarball tools skipped"
        return 1
    }
    failed=0
    while IFS='|' read -r name ver repo tag ax aa min; do
        case "$name" in '' | \#*) continue ;; esac
        case "$arch" in
            x86_64) asset="$ax" ;;
            *) asset="$aa" ;;
        esac
        ensure_bin "$name" "$ver" "$min" \
            "https://github.com/$repo/releases/download/$tag/$asset" "$asset" \
            || failed=$((failed + 1))
    done <"$LOCAL_DIR/manifest"
    [ "$failed" -eq 0 ]
}

echo '==> local: prerequisites'
check_prereqs

echo '==> local: manifest (pinned tarballs)'
if gate local-tools "$LOCAL_DIR/manifest"; then
    if run_manifest; then
        gate_done local-tools "$LOCAL_DIR/manifest"
    else
        echo 'WARN: local: some manifest tools failed — they retry on the next run'
    fi
else
    echo 'local: manifest unchanged since last success, skipped'
fi

# --- Layer 2: toolchain prefixes (cmake, LLVM) --------------------------------
# prefix.sh lands in its own commit; the -x probe keeps this script valid
# at every commit of the rollout (and tolerates a trimmed checkout).

if [ -x "$LOCAL_DIR/prefix.sh" ]; then
    "$LOCAL_DIR/prefix.sh"
fi

# --- Layer 3: nodejs/npm via nvm ----------------------------------------------

ensure_nvm() {
    nvm_ver="v0.40.8"
    if [ -s "$HOME/.nvm/nvm.sh" ]; then
        echo 'local: nvm: already present (~/.nvm)'
        return 0
    fi
    if command -v node >/dev/null 2>&1; then
        cur="$(node --version 2>/dev/null)"
        cur="${cur#v}"
        if ver_ge "${cur:-0}" 18; then
            echo "local: nvm: system node ${cur} kept"
            return 0
        fi
        echo "local: nvm: system node ${cur:-unknown} older than 18, installing nvm"
    fi
    command -v curl >/dev/null 2>&1 || { echo 'WARN: local: nvm: curl missing, skipped'; return 0; }
    command -v git >/dev/null 2>&1 || { echo 'WARN: local: nvm: git missing, skipped'; return 0; }
    tmp="$(mktemp -d 2>/dev/null)" || { echo 'WARN: local: nvm: mktemp failed'; return 0; }
    echo "local: nvm: installing ${nvm_ver}"
    # PROFILE=/dev/null: the installer must never edit the managed rc files.
    if fetch "https://raw.githubusercontent.com/nvm-sh/nvm/${nvm_ver}/install.sh" "$tmp/nvm-install.sh" \
        && PROFILE=/dev/null bash "$tmp/nvm-install.sh"; then
        # shellcheck source=/dev/null  # ~/.nvm/nvm.sh is third-party
        if [ -s "$HOME/.nvm/nvm.sh" ] && . "$HOME/.nvm/nvm.sh" && nvm install --lts; then
            echo 'local: nvm: node LTS installed'
        else
            echo 'WARN: local: nvm installed but node LTS failed — run: nvm install --lts'
        fi
    else
        echo 'WARN: local: nvm installer failed — it retries on the next run'
    fi
    rm -rf "$tmp"
}

echo '==> local: nvm'
ensure_nvm

# --- Layer 4: guarded source builds (zsh, tmux) --------------------------------

if [ -x "$LOCAL_DIR/build.sh" ]; then
    "$LOCAL_DIR/build.sh"
fi

# --- Deliberate omission -------------------------------------------------------

echo 'local: xclip not installed (X11 libs are not userland-installable);'
echo 'local: clipboard uses clip.exe (WSL) / xsel / pbcopy when present'

exit 0
