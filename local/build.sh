#!/usr/bin/env bash
#
# local/build.sh — guarded source builds for the two tools that cannot be
# shipped as single upstream binaries: zsh and tmux. A build only happens
# when the system copy is absent or older than the minimum — every distro
# this repo targets passes both guards, so existing machines never rebuild:
#
#   zsh  5.9.2   min 5.8    (Ubuntu 22.04/24.04 and RHEL 9 all pass)
#   tmux 3.5a    min 3.2a   (same)
#
# Dependency chain, each step built into ~/.local only when missing:
#
#   pkgconf 3.0.7          if pkg-config is absent (tmux's configure
#                          requires it; the tarball still ships autotools)
#   ncurses 6.6            if the headers are absent (STATIC: --without-shared)
#   libevent 2.1.13-stable if the headers are absent (STATIC: --disable-shared)
#   tmux 3.5a, zsh 5.9.2
#
# ncurses and libevent are deliberately built static-only: tmux and zsh
# then embed their dependencies and never need LD_LIBRARY_PATH to run.
# libevent is configured --disable-openssl for the same reason — tmux
# does not use it and system openssl headers may be absent.
#
# Compiler: system gcc if present, else the clang of the local LLVM
# prefix, else system clang; with none, or without make, this layer WARNs
# and exits — the tarball layers above need no compiler at all.
#
# chsh is out of scope (it needs root): tmux already pins default-shell,
# and terminals launch zsh from PATH, where ~/.local/bin leads.
#
# Gate: local-build, over this file (the pins live here).
# Failure policy: WARN and move on; one failed build never blocks the rest.

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

PREFIX="$HOME/.local"
JOBS="$(nproc 2>/dev/null || echo 2)"

# Version pins.
ZSH_VER="5.9.2"
ZSH_MIN="5.8"
TMUX_VER="3.5a"
TMUX_MIN="3.2a"
PKGCONF_VER="3.0.7"
NCURSES_VER="6.6"
LIBEVENT_VER="2.1.13-stable"

# --- Toolchain probe -----------------------------------------------------------

select_compiler() {
    if command -v gcc >/dev/null 2>&1; then
        CC="$(command -v gcc)"
        CXX="$(command -v g++ 2>/dev/null || echo "$CC")"
    elif [ -x "$LOCAL_BIN/clang" ]; then
        CC="$LOCAL_BIN/clang"
        CXX="$LOCAL_BIN/clang++"
    elif command -v clang >/dev/null 2>&1; then
        CC="$(command -v clang)"
        CXX="$(command -v clang++)"
    else
        return 1
    fi
    export CC CXX
    export CPPFLAGS="-I$PREFIX/include ${CPPFLAGS:-}"
    export LDFLAGS="-L$PREFIX/lib ${LDFLAGS:-}"
    export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PREFIX/share/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
    echo "local: builds use CC=$CC"
}

# --- Generic source build ------------------------------------------------------

build_source() {  # build_source <name> <url> <tarball> <srcdir> [configure args...]
    name="$1" url="$2" tball="$3" src="$4"
    shift 4
    tmp="$(mktemp -d 2>/dev/null)" || {
        echo "WARN: local: $name: mktemp failed"
        return 1
    }
    echo "local: $name: downloading ${tball}"
    if ! fetch "$url" "$tmp/$tball"; then
        echo "WARN: local: $name: download failed"
        rm -rf "$tmp"
        return 1
    fi
    if ! extract "$tmp/$tball" "$tmp/x" || [ ! -d "$tmp/x/$src" ]; then
        echo "WARN: local: $name: extraction failed"
        rm -rf "$tmp"
        return 1
    fi
    echo "local: $name: configuring + building (-j$JOBS, a few minutes)"
    if (cd "$tmp/x/$src" \
        && ./configure --prefix="$PREFIX" "$@" >>"$tmp/build.log" 2>&1 \
        && make -s -j"$JOBS" >>"$tmp/build.log" 2>&1 \
        && make install >>"$tmp/build.log" 2>&1); then
        rm -rf "$tmp"
        echo "local: $name: installed -> $PREFIX"
        return 0
    fi
    echo "WARN: local: $name: build failed, last lines:"
    tail -5 "$tmp/build.log" 2>/dev/null | sed 's/^/WARN: local:   /'
    rm -rf "$tmp"
    return 1
}

# --- Guards --------------------------------------------------------------------

need_tool() {  # need_tool <bin> <min> <pin> — returns 0 when a build IS required
    bin="$1" min="$2" pin="$3"
    if [ -x "$LOCAL_BIN/$bin" ]; then
        cur="$(bin_version "$LOCAL_BIN/$bin")"
        if ver_ge "$cur" "$pin"; then
            echo "local: $bin: ${cur} already installed (local)"
            return 1
        fi
        echo "local: $bin: local ${cur} older than ${pin}, rebuilding"
        return 0
    fi
    if command -v "$bin" >/dev/null 2>&1; then
        cur="$(bin_version "$(command -v "$bin")")"
        if ver_ge "$cur" "$min"; then
            echo "local: $bin: system ${cur} kept"
            return 1
        fi
        echo "local: $bin: system ${cur} below ${min}, building ${pin}"
        return 0
    fi
    echo "local: $bin: not found, building ${pin}"
    return 0
}

have_header() {  # have_header <header.h> — can the compiler see it
    printf '#include <%s>\nint main(void){return 0;}\n' "$1" \
        | "$CC" -x c - -o /dev/null >/dev/null 2>&1
}

# --- The layer -------------------------------------------------------------------

run_build() {
    want_zsh=0
    want_tmux=0
    need_tool zsh "$ZSH_MIN" "$ZSH_VER" && want_zsh=1
    need_tool tmux "$TMUX_MIN" "$TMUX_VER" && want_tmux=1
    if [ "$want_zsh" -eq 0 ] && [ "$want_tmux" -eq 0 ]; then
        echo 'local: nothing to build (system zsh and tmux are fine)'
        return 0
    fi

    if ! select_compiler; then
        echo 'WARN: local: no compiler (gcc/clang) — zsh/tmux source builds skipped'
        echo 'WARN: local: hint: sudo dnf install gcc make / sudo apt-get install gcc make'
        return 1
    fi
    command -v make >/dev/null 2>&1 || {
        echo 'WARN: local: make missing — zsh/tmux source builds skipped'
        return 1
    }

    failed=0

    # tmux's configure hard-requires pkg-config; pkgconf's autotools path
    # installs the pkgconf binary, alias the traditional name when absent.
    if [ "$want_tmux" -eq 1 ] && ! command -v pkg-config >/dev/null 2>&1; then
        build_source pkgconf \
            "https://distfiles.ariadne.space/pkgconf/pkgconf-$PKGCONF_VER.tar.xz" \
            "pkgconf-$PKGCONF_VER.tar.xz" "pkgconf-$PKGCONF_VER" \
            || failed=1
        command -v pkg-config >/dev/null 2>&1 \
            || ln -sfn "$PREFIX/bin/pkgconf" "$LOCAL_BIN/pkg-config"
    fi

    if [ "$want_tmux" -eq 1 ] || [ "$want_zsh" -eq 1 ]; then
        have_header "ncurses.h" || build_source ncurses \
            "https://invisible-island.net/archives/ncurses/ncurses-$NCURSES_VER.tar.gz" \
            "ncurses-$NCURSES_VER.tar.gz" "ncurses-$NCURSES_VER" \
            --enable-widec --without-shared --without-progs --without-ada --without-debug \
            || failed=1
    fi

    if [ "$want_tmux" -eq 1 ]; then
        have_header "event2/event.h" || build_source libevent \
            "https://github.com/libevent/libevent/releases/download/release-$LIBEVENT_VER/libevent-$LIBEVENT_VER.tar.gz" \
            "libevent-$LIBEVENT_VER.tar.gz" "libevent-$LIBEVENT_VER" \
            --disable-shared --disable-openssl --enable-static \
            || failed=1

        build_source tmux \
            "https://github.com/tmux/tmux/releases/download/$TMUX_VER/tmux-$TMUX_VER.tar.gz" \
            "tmux-$TMUX_VER.tar.gz" "tmux-$TMUX_VER" \
            || failed=1
    fi

    if [ "$want_zsh" -eq 1 ]; then
        build_source zsh \
            "https://www.zsh.org/pub/zsh-$ZSH_VER.tar.xz" \
            "zsh-$ZSH_VER.tar.xz" "zsh-$ZSH_VER" \
            --enable-multibyte \
            || failed=1
    fi

    [ "$failed" -eq 0 ]
}

if gate local-build "$LOCAL_DIR/build.sh"; then
    if run_build; then
        gate_done local-build "$LOCAL_DIR/build.sh"
    else
        echo 'WARN: local: a source build failed — it retries on the next run'
    fi
else
    echo 'local: source builds unchanged since last success, skipped'
fi

exit 0
