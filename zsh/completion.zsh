# zsh/completion.zsh — completion styles.
# Sourced by the loader AFTER compinit (see zsh/zshrc.symlink): zstyles are
# read at completion time, so this is the natural place for tuning.

# Matching, progressively looser: exact first, then case-insensitive, then
# partial-words (foo-b completes to foo-bar across . _ - boundaries), then
# substring on both sides. The chain oh-my-zsh's library used to set.
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
# Typo tolerance: when nothing matches, _correct rewrites the word under
# the cursor (cd Docmunts-[Tab] still completes to Documents/) and
# _approximate retries with near misses; max-errors caps how wrong the
# input may be. Also from oh-my-zsh's library, lost in the migration.
zstyle ':completion:*' completer _expand _complete _ignored _correct _approximate
zstyle ':completion:*' max-errors 4
zstyle ':completion:*:corrections' format '%F{yellow}!- %d (errors: %e) -!%f'
# Arrow-navigable menu: Tab opens the candidate list with a cursor moved
# by the arrow keys. Native zsh — the zstyle oh-my-zsh's library used to
# set before this setup dropped oh-my-zsh for pinned plugins.
zstyle ':completion:*' menu select
# Color the candidate list like `ls` does (dirs blue, executables red...).
zstyle ':completion:*:default' list-colors 'di=34:ln=35:so=32:pi=33:ex=31:bd=1;36:cd=1;33:'
# While unprocessed input is pending (e.g. pasted text), insert TAB
# literally instead of triggering completion.
zstyle ':completion:*' insert-tab pending
