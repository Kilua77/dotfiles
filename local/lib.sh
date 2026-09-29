#!/usr/bin/env bash
#
# lib.sh — shared helpers for the local/ topic (sourced, not run; same
# convention as script/gate.sh). Everything here is userland: downloads go
# to a mktemp dir, binaries land in ~/.local/bin, nobody ever elevates.
#
#   lb_arch          print x86_64 / aarch64 for the running machine
#   ver_ge <a> <b>   true when version a >= b (dotted numeric; letters in a
#                    component are stripped, so tmux "3.5a" compares as 3.5)
#   bin_version <p>  first x.y.z-looking token of "<p> --version" (whole
#                    output — shellcheck prints its version on line 2)
#   fetch <url> <d>  curl a file with retries
#   extract <f> <d>  unpack .tar.gz / .tgz / .tar.xz / .zip into a directory
#   place_bin <s> <d>  copy a binary into place via same-directory mv
#   tarball_install <name> <url> <asset>
#                    download + extract + place ONE binary asset (raw
#                    single-file assets like jq-linux-amd64 are placed as-is)
#   ensure_bin <name> <pin> <min> <url> <asset>
#                    the skip-if-present ladder:
#                      1. ~/.local/bin/<name> is ours — it wins; refreshed
#                         only when older than the pin (never downgraded)
#                      2. a system copy >= min is kept as-is; "-" never
#                         accepts a system copy
#                      3. otherwise the pinned tarball is installed
#
# Every failure path prints a "WARN: local: ..." line and returns 1 —
# callers decide; script/install counts the WARNs for its summary.

# Where the local layer installs. ~/.local/bin is on PATH via zsh/zshenv.
LOCAL_BIN="${LOCAL_BIN:-$HOME/.local/bin}"
LOCAL_OPT="${LOCAL_OPT:-$HOME/.local/opt}"

lb_arch() {
    case "$(uname -m)" in
        x86_64) echo x86_64 ;;
        aarch64 | arm64) echo aarch64 ;;
        *) return 1 ;;
    esac
}

ver_ge() {
    awk -v A="$1" -v B="$2" 'BEGIN {
        na = split(A, aa, "."); nb = split(B, bb, ".")
        n = na > nb ? na : nb
        for (i = 1; i <= n; i++) {
            a = (i <= na) ? aa[i] : 0; b = (i <= nb) ? bb[i] : 0
            gsub(/[^0-9]/, "", a); gsub(/[^0-9]/, "", b)
            if (a + 0 > b + 0) exit 0
            if (a + 0 < b + 0) exit 1
        }
        exit 0
    }'
}

bin_version() {
    v="$("$1" --version 2>/dev/null | grep -oE '[0-9]+([.][0-9]+)+' | head -1)"
    printf '%s' "${v:-unknown}"
}

fetch() {  # fetch <url> <dest>
    curl -fsSL --connect-timeout 15 --retry 2 "$1" -o "$2"
}

extract() {  # extract <archive> <destdir>
    mkdir -p "$2" || return 1
    case "$1" in
        *.tar.gz | *.tgz) tar -xzf "$1" -C "$2" ;;
        *.tar.xz) tar -xJf "$1" -C "$2" ;;
        *.zip) unzip -q "$1" -d "$2" ;;
        *)
            echo "WARN: local: unknown archive type: $1"
            return 1
            ;;
    esac
}

place_bin() {  # place_bin <src> <dest> — same-directory mv keeps it atomic
    mkdir -p "$(dirname "$2")" || return 1
    staging="$2.new.$$"
    if ! cp "$1" "$staging"; then
        echo "WARN: local: copy failed: $2"
        rm -f "$staging"
        return 1
    fi
    chmod 0755 "$staging"
    mv -f "$staging" "$2"
}

tarball_install() {  # tarball_install <name> <url> <asset>
    name="$1" url="$2" asset="$3"
    tmp="$(mktemp -d 2>/dev/null)" || {
        echo "WARN: local: $name: mktemp failed"
        return 1
    }
    echo "local: $name: downloading ${asset}"
    if ! fetch "$url" "$tmp/$asset"; then
        echo "WARN: local: $name: download failed"
        rm -rf "$tmp"
        return 1
    fi
    case "$asset" in
        *.tar.gz | *.tgz | *.tar.xz | *.zip)
            if ! extract "$tmp/$asset" "$tmp/x"; then
                echo "WARN: local: $name: extraction failed"
                rm -rf "$tmp"
                return 1
            fi
            # Release layouts vary (binary at the root, inside a versioned
            # dir, next to completions) — the named executable is wherever
            # it is; a plain file match cannot catch the completions.
            bin="$(find "$tmp/x" -type f -name "$name" | head -1)"
            if [ -z "$bin" ]; then
                echo "WARN: local: $name: no '$name' executable inside $asset"
                rm -rf "$tmp"
                return 1
            fi
            ;;
        *) # raw single-file asset (jq ships jq-linux-<arch>)
            bin="$tmp/$asset"
            ;;
    esac
    if ! place_bin "$bin" "$LOCAL_BIN/$name"; then
        rm -rf "$tmp"
        return 1
    fi
    rm -rf "$tmp"
    echo "local: $name: installed -> $LOCAL_BIN/$name"
}

ensure_bin() {  # ensure_bin <name> <pin> <min> <url> <asset>
    name="$1" pin="$2" min="$3" url="$4" asset="$5"
    ours="$LOCAL_BIN/$name"

    if [ -x "$ours" ]; then
        cur="$(bin_version "$ours")"
        if ver_ge "$cur" "$pin"; then
            echo "local: $name: ${cur} already installed"
            return 0
        fi
        echo "local: $name: ${cur} older than pin ${pin}, refreshing"
    elif command -v "$name" >/dev/null 2>&1; then
        sys="$(command -v "$name")"
        cur="$(bin_version "$sys")"
        if [ "$min" != "-" ] && ver_ge "$cur" "$min"; then
            echo "local: $name: system ${cur} kept (${sys})"
            return 0
        fi
        echo "local: $name: system ${cur} below min ${min}, installing pin ${pin}"
    else
        echo "local: $name: not found, installing pin ${pin}"
    fi
    tarball_install "$name" "$url" "$asset"
}
