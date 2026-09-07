#!/bin/sh
#
# zsh/install.sh — clone the pinned zsh plugins into
# $HOME/.local/share/zsh/plugins/ (no plugin manager, no submodules),
# and install the Starship prompt binary on Linux.
#
# Every plugin is pinned to an exact ref (tag or commit). Safe to re-run:
#   - no clone            -> clone, then detach at the pin
#   - clone at the pin    -> untouched
#   - clone drifted away  -> fetch + checkout --detach back to the pin
#     (drift happens after a manual checkout, or when someone "just pulled")
#
# The interactive side (source order, bindkeys) lives in zsh/plugins.zsh;
# this script only puts bytes on disk.

set -eu

PLUGINS_DIR="$HOME/.local/share/zsh/plugins"

# pin <repo-url> <dir-name> <ref>
pin() {
  url=$1
  name=$2
  ref=$3
  dir=$PLUGINS_DIR/$name

  # A directory without .git is a leftover extract (e.g. from a previous
  # tarball-based setup) — replace it with a proper clone so drift repair works.
  if [ -d "$dir" ] && [ ! -d "$dir/.git" ]; then
    printf '==> replace %s: %s exists but is not a git clone\n' "$name" "$dir"
    rm -rf "$dir"
  fi

  if [ ! -d "$dir/.git" ]; then
    printf '==> clone %s at %s\n' "$name" "$ref"
    git clone --quiet "$url" "$dir"
    git -C "$dir" checkout --quiet --detach "$ref"
    return 0
  fi

  current=$(git -C "$dir" rev-parse HEAD)
  pinned=$(git -C "$dir" rev-parse --quiet --verify "${ref}^{commit}") || pinned=""
  if [ -n "$pinned" ] && [ "$current" = "$pinned" ]; then
    printf '==> ok %s (%s)\n' "$name" "$ref"
    return 0
  fi

  printf '==> repair %s: drifted from %s, re-pinning to %s\n' \
    "$name" "${current:-unknown}" "$ref"
  git -C "$dir" fetch --quiet --all --tags
  git -C "$dir" checkout --quiet --detach "$ref"
}

mkdir -p "$PLUGINS_DIR"

# Order matters at load time (see zsh/plugins.zsh); keep the list aligned.
pin https://github.com/zsh-users/zsh-autosuggestions \
  zsh-autosuggestions v0.7.1
pin https://github.com/zsh-users/zsh-syntax-highlighting \
  zsh-syntax-highlighting 0.8.0
pin https://github.com/zsh-users/zsh-history-substring-search \
  zsh-history-substring-search 14c8d2e0ffaee98f2df9850b19944f32546fdea5
pin https://github.com/zsh-users/zsh-completions \
  zsh-completions 0.35.0
pin https://github.com/jimhester/per-directory-history \
  per-directory-history fbbf294abfa6819bb12df7d111c800f4f3a3dd07

# --- Prompt: Starship ---------------------------------------------------------
# The prompt is Starship (config in zsh/config/starship.toml.symlink, init in
# tools.zsh behind a `command -v` guard — a missing binary silently keeps the
# default zsh prompt). Homebrew owns it on macOS (Brewfile); Ubuntu does not
# package starship at all, so on Linux the pinned official tarball is installed
# to ~/.local/bin. Same policy as nvim/install.sh:
#   - an existing foreign starship (brew, cargo, distro package) is kept
#   - our own ~/.local/bin/starship is refreshed when the pin moves
#   - every failure WARNs and the run continues
#
# Bump the pin: update STARSHIP_VER, then re-run this script. Note the arch
# triplets are not symmetric: x86_64 has a gnu build, aarch64 only musl.

install_starship() {
  STARSHIP_VER="1.26.0"

  # macOS: Homebrew owns the prompt binary (see the Brewfile).
  [ "$(uname -s)" = "Darwin" ] && return 0

  case "$(uname -m)" in
    x86_64) starship_target="x86_64-unknown-linux-gnu" ;;
    aarch64 | arm64) starship_target="aarch64-unknown-linux-musl" ;;
    *)
      echo "WARN: unsupported architecture $(uname -m) for starship, keeping the default prompt"
      return 0
      ;;
  esac

  if [ -x "$HOME/.local/bin/starship" ]; then
    if [ "$($HOME/.local/bin/starship --version | head -1 | awk '{print $2}')" = "$STARSHIP_VER" ]; then
      echo "zsh: starship ok (${STARSHIP_VER} already installed)"
      return 0
    fi
    echo "zsh: starship: refreshing pin -> ${STARSHIP_VER}"
  elif command -v starship >/dev/null 2>&1; then
    echo "zsh: starship ok (foreign install at $(command -v starship), keeping it)"
    return 0
  fi

  url="https://github.com/starship/starship/releases/download/v${STARSHIP_VER}/starship-${starship_target}.tar.gz"
  tmp="$(mktemp -d)" || {
    echo "WARN: mktemp failed, skipping starship install"
    return 0
  }

  echo "zsh: downloading starship ${STARSHIP_VER} (${starship_target})"
  # The tarball holds a single prebuilt `starship` binary at its root.
  if ! curl -fsSL "$url" | tar -xz -C "$tmp"; then
    echo "WARN: starship download/extract failed, keeping the default prompt"
    rm -rf "$tmp"
    return 0
  fi

  mkdir -p "$HOME/.local/bin"
  if mv "$tmp/starship" "$HOME/.local/bin/starship"; then
    chmod +x "$HOME/.local/bin/starship"
    echo "zsh: starship ${STARSHIP_VER} installed -> ~/.local/bin/starship"
  else
    echo "WARN: starship install step failed, keeping the default prompt"
  fi
  rm -rf "$tmp"
}

install_starship
