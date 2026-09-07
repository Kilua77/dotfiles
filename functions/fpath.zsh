# functions/fpath.zsh — make this topic's functions autoloadable.
# fpath AND autoload both live here (not in zsh/config.zsh) so the topic is
# self-contained: drop a file in functions/ and it works, no registration.
# The loader sources */path.zsh before compinit, so the _* completion files
# are already visible to it.

fpath=("$DOTFILES/functions" $fpath)

# Mark every function in the directory for autoload, skipping the .zsh
# bookkeeping files (this one included) — new functions need no edit here.
for fn in "$DOTFILES"/functions/*(N:t); do
  case "$fn" in
    *.zsh) ;;
    *) autoload -U "$fn" ;;
  esac
done
