# zsh/env.zsh — interactive-shell environment.
# Non-secret, machine-independent values only: secrets and per-machine
# overrides (feature flags, compiler choice) belong in ~/.localrc —
# see zsh/localrc.example.

export EDITOR=nvim
export VISUAL=nvim

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
