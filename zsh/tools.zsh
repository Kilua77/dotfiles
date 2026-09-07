# zsh/tools.zsh — modern CLI tools, each guarded so a missing binary never
# breaks the shell. Loaded after zsh/plugins.zsh.

# Colored man pages: vendored in this repo (no download needed). The file
# lives one level deeper than the loader's depth-1 *.zsh glob, on purpose —
# it is pulled in here, not auto-sourced.
if [ -f "$DOTFILES/zsh/plugins/colored-man-pages.plugin.zsh" ]; then
    source "$DOTFILES/zsh/plugins/colored-man-pages.plugin.zsh"
fi

# Prompt.
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"
# Smarter cd with frecency tracking (replaces the old rupa/z).
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"

if command -v fzf >/dev/null 2>&1; then
    # Probe first: `fzf --zsh` exists only on fzf >= 0.48; on older builds
    # it fails and prints nothing (hence 2>/dev/null on both calls).
    if fzf --zsh >/dev/null 2>&1; then
        source <(fzf --zsh 2>/dev/null)
    elif [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]; then
        # Older fzf as packaged by Debian: use the distro-shipped files.
        source /usr/share/doc/fzf/examples/key-bindings.zsh
        [ -f /usr/share/doc/fzf/examples/completion.zsh ] && \
            source /usr/share/doc/fzf/examples/completion.zsh
    fi
fi
