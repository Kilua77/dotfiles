#!/bin/sh
#
# zsh/install.sh — clone the pinned zsh plugins into
# $HOME/.local/share/zsh/plugins/ (no plugin manager, no submodules).
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
