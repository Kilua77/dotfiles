# zsh/env.zsh — interactive-shell environment.
# Non-secret, machine-independent values only: secrets and per-machine
# overrides (feature flags, compiler choice) belong in ~/.localrc —
# see zsh/localrc.example.

# Editors. Inside a VS Code integrated terminal — live IPC socket (refreshed
# first by vscode/env.zsh when tmux had frozen a stale one) and `code` on
# PATH — the window becomes the editor: everything that shells out (git
# commits, Claude Code's ctrl+G prompt editor) opens a tab there instead of
# nvim in the terminal. Everywhere else, nvim.
if [[ -n "$VSCODE_IPC_HOOK_CLI" && -S "$VSCODE_IPC_HOOK_CLI" ]] && command -v code >/dev/null 2>&1; then
  export EDITOR="code --wait"
  export VISUAL="code --wait"
else
  export EDITOR=nvim
  export VISUAL=nvim
fi

# Root directory for personal projects — used by the `c` jump function
# (functions/c) and its completion (functions/_c).
export PROJECTS="$HOME/Workspace"

# Fallback locale for hosts that ship none.
export LANG="${LANG:-en_US.UTF-8}"

# nvm takes ~1s to source; load it on first use instead of at startup.
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [ -s "$NVM_DIR/nvm.sh" ]; then
  nvm() {
    unset -f nvm              # drop this stub...
    source "$NVM_DIR/nvm.sh"  # ...load the real nvm once...
    nvm "$@"                  # ...and replay the original arguments.
  }
fi
