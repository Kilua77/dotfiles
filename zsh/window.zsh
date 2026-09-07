# zsh/window.zsh — automatic terminal window title.
# Restored from the legacy dotfiles (originally from
# http://dotfiles.org/~_why/.zshrc), adapted for modern shells: hooks are
# registered through add-zsh-hook so they compose with other precmd/preexec
# hooks, and tmux is handled alongside screen/xterm.

# title <command> <title-text> <long-text> — set the terminal window title.
# $1 command name (screen/tmux tab title), $2 short title (xterm window
# title), $3 long form shown by screen/tmux.
title() {
  # escape '%' chars in $1, make nonprintables visible
  a=${(V)1//\%/\%\%}

  # Truncate command, and join lines.
  a=$(print -Pn "%40>...>$a" | tr -d "\n")

  case "$TERM" in
    screen|screen-*|tmux|tmux-*)
      print -Pn "\ek$a:$3\e\\" # screen/tmux title (in ^A")
      ;;
    xterm*|rxvt*|st*)
      print -Pn "\e]2;$2\a" # plain xterm-style title ($3 carries the pwd)
      ;;
  esac
}

# Only install the hooks in terminals that understand title escapes —
# dumb pipes (ssh -t less, CI, Emacs shells) must stay untouched.
case "$TERM" in
  screen*|tmux*|xterm*|rxvt*|st*)
    autoload -Uz add-zsh-hook

    _dotfiles_window_precmd() {
      title zsh '%~' '%n@%m: %~'
    }

    _dotfiles_window_preexec() {
      title "$1" '%~' "%n@%m: %~ (%$COLUMNS)"
    }

    add-zsh-hook precmd  _dotfiles_window_precmd
    add-zsh-hook preexec _dotfiles_window_preexec
    ;;
esac
