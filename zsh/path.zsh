# zsh/path.zsh — put the repo's bin/ topic on PATH.
# Sourced in the first loader phase, before any other topic file.
# `typeset -U path` deduplicates the array (and PATH with it), so repeated
# shells or reloads never grow a stack of identical entries.
typeset -U path
path=("$DOTFILES/bin" $path)
