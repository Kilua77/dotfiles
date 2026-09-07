# Colored man pages.
# Vendored from the oh-my-zsh colored-man-pages plugin (public domain).
#
# Overrides the `man` command to export less "termcap" escape variables for
# the duration of a single call; less then renders bold/underline sections
# of the man page in color. `local -x` keeps them out of the shell
# environment once the call finishes.
#
# Not auto-sourced: the loader's depth-1 glob does not reach this deep —
# zsh/tools.zsh sources it explicitly.

man() {
    local -x LESS_TERMCAP_mb=$'\e[1;31m'  # begin blink (rarely emitted)
    local -x LESS_TERMCAP_md=$'\e[1;37m'  # begin bold — section headings
    local -x LESS_TERMCAP_me=$'\e[0m'     # end bold/blink
    local -x LESS_TERMCAP_se=$'\e[0m'     # end standout
    local -x LESS_TERMCAP_so=$'\e[1;47m'  # begin standout — status line
    local -x LESS_TERMCAP_ue=$'\e[0m'     # end underline
    local -x LESS_TERMCAP_us=$'\e[0;32m'  # begin underline — options
    local -x LESS=-R                     # keep ANSI escapes intact in less
    command man "$@"
}
