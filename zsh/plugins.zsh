# zsh/plugins.zsh — pinned zsh plugins, cloned by zsh/install.sh into
# $HOME/.local/share/zsh/plugins/.
#
# Every source is guarded so a missing plugin never breaks the shell
# (fresh machine, partial install). Order matters:
#   1. zsh-autosuggestions — must come first; it creates the widgets the
#      next two wrap.
#   2. zsh-syntax-highlighting — wraps the widgets autosuggestions left.
#   3. zsh-history-substring-search — always LAST, for the same reason,
#      and its Up/Down bindkeys come right after it.

ZSH_PLUGINS="$HOME/.local/share/zsh/plugins"

if [ -f "$ZSH_PLUGINS/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
    # Style the inline suggestion BEFORE sourcing: the plugin snapshots
    # the variable at load time (fg=9 = bright red; habit carried over
    # from the legacy dotfiles).
    export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=9'
    source "$ZSH_PLUGINS/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

if [ -f "$ZSH_PLUGINS/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
    source "$ZSH_PLUGINS/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

if [ -f "$ZSH_PLUGINS/zsh-history-substring-search/zsh-history-substring-search.zsh" ]; then
    source "$ZSH_PLUGINS/zsh-history-substring-search/zsh-history-substring-search.zsh"
    # Up/Down (both terminal and application cursor key sequences)
    # search history for anything matching the typed prefix.
    bindkey '^[[A' history-substring-search-up
    bindkey '^[[B' history-substring-search-down
    bindkey '^[OA' history-substring-search-up
    bindkey '^[OB' history-substring-search-down
fi

if [ -f "$ZSH_PLUGINS/per-directory-history/per-directory-history.zsh" ]; then
    # Two histories: everything is always SAVED to both the global history
    # (the HISTFILE set in config.zsh) and a per-directory one; the toggle
    # only switches which one Up/Down searches.
    #   Ctrl-G  toggle  "using local history" <-> "using global history"
    # Shells start in local (per-directory) mode. Must load after config.zsh
    # (it snapshots $HISTFILE as the global history at load time).
    HISTORY_BASE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/directory_history"
    source "$ZSH_PLUGINS/per-directory-history/per-directory-history.zsh"
fi

unset ZSH_PLUGINS
