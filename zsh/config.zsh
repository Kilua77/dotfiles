# zsh/config.zsh — history, core options and key bindings.

# --- history -------------------------------------------------------------
# Keep the history file under XDG_STATE_HOME, not scattered in $HOME.
HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
mkdir -p "${HISTFILE:h}"  # :h is the zsh dirname modifier

HISTSIZE=50000  # lines kept in memory per session
SAVEHIST=50000  # lines persisted to $HISTFILE

# Share one history file across running shells; record timestamps.
setopt SHARE_HISTORY EXTENDED_HISTORY
# Drop duplicates and superfluous blanks; confirm history expansion before run.
setopt HIST_IGNORE_ALL_DUPS HIST_REDUCE_BLANKS HIST_VERIFY
# Spell-check commands; complete inside the word under the cursor.
setopt CORRECT COMPLETE_IN_WORD
# Keep options and traps function-local while a function runs.
setopt LOCAL_OPTIONS LOCAL_TRAPS
# Background jobs keep running (and their speed) after logout; stay quiet
# in list completions.
setopt NO_BG_NICE NO_HUP NO_LIST_BEEP
# Allow '# comments' on the interactive command line.
setopt INTERACTIVE_COMMENTS
# Expand parameter expressions in the prompt (needed by prompt frameworks).
setopt PROMPT_SUBST

# --- key bindings ----------------------------------------------------------
# Force the emacs keymap: EDITOR contains "vi" (nvim), which would
# otherwise make zsh start in vi insert mode.
bindkey -e

# Home / End — the \e[1~/\e[4~ xterm sequences plus the plain \e[H/\e[F
# variants sent by darwin terminal emulators.
bindkey '\e[1~' beginning-of-line
bindkey '\e[4~' end-of-line
bindkey '\e[H'  beginning-of-line
bindkey '\e[F'  end-of-line
# Delete deletes forward.
bindkey '\e[3~' delete-char
# Ctrl+Left / Ctrl+Right move by word.
bindkey '\e[1;5D' backward-word
bindkey '\e[1;5C' forward-word
