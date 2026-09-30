#!/usr/bin/env bash
#
# fonts/install.sh — the Nerd Font behind every glyph this repo's configs
# draw: LazyVim's lualine/mini.icons, starship's module icons, Claude
# Code's statusline symbols. They live in the Nerd Font private-use area,
# which stock monospace fonts (DejaVu Sans Mono & co.) do not cover — the
# tofu boxes they print are a font gap, never a broken plugin install.
#
# Linux, userland only: the JetBrainsMono "Mono" TTFs from the pinned
# ryanoasis/nerd-fonts release, unpacked into ~/.local/share/fonts and
# registered with fc-cache. The same font macOS gets from the Brewfile
# (cask font-jetbrains-mono-nerd-font); this file never runs there.
#
# Selecting the font in the terminal emulator is per-machine state this
# repo deliberately does not touch: fc-cache only makes the family
# selectable. GNOME Terminal: uncheck "Use the system fixed-width font",
# pick "JetBrainsMono Nerd Font Mono".
#
# Gate: fonts-nerd, over this file (the pin lives here).
# Failure policy: WARN and move on (script/install counts the WARNs).

set -u

if [ "$(uname -s)" = "Darwin" ]; then
    exit 0
fi

FONTS_DIR="$(cd "$(dirname "$0")" && pwd -P)"
# shellcheck source=/dev/null  # gate.sh is linted on its own
. "$FONTS_DIR/../script/gate.sh"

NF_VER="3.4.0"
FAMILY="JetBrainsMono Nerd Font Mono"
DEST="$HOME/.local/share/fonts/JetBrainsMono-NF"

run_font() {
    # Any registered Nerd Font family wins — a system package or manual
    # install is never replaced (the skip-if-present ladder, on fonts).
    if command -v fc-list >/dev/null 2>&1 \
        && fc-list :family 2>/dev/null | grep -Fqi 'Nerd Font'; then
        echo 'fonts: a Nerd Font family is already registered'
        return 0
    fi
    for p in curl tar xz; do
        command -v "$p" >/dev/null 2>&1 && continue
        echo "WARN: fonts: '$p' missing — install it system-wide (sudo dnf install $p / sudo apt-get install $p)"
        return 1
    done
    command -v fc-cache >/dev/null 2>&1 || {
        echo 'WARN: fonts: fc-cache missing (fontconfig not installed?) — Nerd Font skipped'
        echo 'WARN: fonts: hint: sudo dnf install fontconfig / sudo apt-get install fontconfig'
        return 1
    }

    if [ -d "$DEST" ] && ls "$DEST"/JetBrainsMonoNerdFontMono-*.ttf >/dev/null 2>&1; then
        echo "fonts: ${FAMILY} already unpacked (~/.local/share/fonts)"
    else
        tmp="$(mktemp -d 2>/dev/null)" || { echo 'WARN: fonts: mktemp failed'; return 1; }
        echo 'fonts: downloading JetBrainsMono Nerd Font (Mono weights)'
        if ! curl -fsSL --connect-timeout 15 --retry 2 \
            -o "$tmp/JetBrainsMono.tar.xz" \
            "https://github.com/ryanoasis/nerd-fonts/releases/download/v${NF_VER}/JetBrainsMono.tar.xz"; then
            echo 'WARN: fonts: download failed — it retries on the next run'
            rm -rf "$tmp"
            return 1
        fi
        mkdir -p "$tmp/x" "$DEST" || { rm -rf "$tmp"; return 1; }
        # Only the Mono-spacing family (icons forced to one cell): the full
        # release also ships NL/proportional variants this setup has no use
        # for. --wildcards is GNU tar; this path is Linux-only.
        if ! tar -xJf "$tmp/JetBrainsMono.tar.xz" -C "$tmp/x" \
            --wildcards 'JetBrainsMonoNerdFontMono-*.ttf'; then
            echo 'WARN: fonts: extraction failed — it retries on the next run'
            rm -rf "$tmp"
            return 1
        fi
        cp -f "$tmp/x"/JetBrainsMonoNerdFontMono-*.ttf "$DEST"/ || { rm -rf "$tmp"; return 1; }
        rm -rf "$tmp"
        echo "fonts: installed -> $DEST"
    fi

    fc-cache -f "$DEST" >/dev/null 2>&1
    fc-list :family 2>/dev/null | grep -Fqi "$FAMILY" || {
        echo "WARN: fonts: ${FAMILY} not visible to fontconfig after fc-cache"
        return 1
    }
    echo "fonts: ${FAMILY} registered"
    return 0
}

if gate fonts-nerd "$FONTS_DIR/install.sh"; then
    if run_font; then
        gate_done fonts-nerd "$FONTS_DIR/install.sh"
    else
        echo 'WARN: fonts: Nerd Font install failed — it retries on the next run'
    fi
else
    echo 'fonts: unchanged since last success, skipped'
fi

exit 0
