# zsh/completion.zsh — completion styles.
# Sourced by the loader AFTER compinit (see zsh/zshrc.symlink): zstyles are
# read at completion time, so this is the natural place for tuning.

# Case-insensitive matching: lowercase input matches any-case candidate.
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
# While unprocessed input is pending (e.g. pasted text), insert TAB
# literally instead of triggering completion.
zstyle ':completion:*' insert-tab pending
