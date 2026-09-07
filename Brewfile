# Brewfile -- Homebrew bundle for the macOS side of these dotfiles.
#
# Applied by script/install via `brew bundle --file=Brewfile`, hash-gated on
# this file (see script/gate.sh): an unchanged Brewfile is a no-op.
# Manual run (from the repo root): brew bundle --file=Brewfile
#
# Linux equivalents live in apt/packages (installed by apt/install.sh).

# --- Casks (GUI applications and fonts) --------------------------------------

cask "visual-studio-code"
cask "ghostty"
cask "font-jetbrains-mono-nerd-font"

# --- Formulae (CLI tools) ----------------------------------------------------

# Shell and terminal
brew "zsh"
brew "tmux"
brew "starship" # Linux: pinned tarball via zsh/install.sh (not in Ubuntu repos)
brew "zoxide"
brew "fzf"
brew "eza"
brew "bat"
brew "ripgrep"
brew "fd"
brew "duf"
brew "dust"
brew "git-delta"
brew "lazygit"
brew "gh"
brew "jq"

# Editor
brew "neovim"

# Linting
brew "shellcheck"

# C/C++ build toolchain
brew "cmake"
brew "ninja"
brew "meson"
brew "llvm"
brew "clang-format"
brew "ccache"
brew "nvm"
brew "sfml"

# --- Heavy / optional --------------------------------------------------------
# Qt is several GB and slow to pour; the VS Code Qt extensions can fetch their
# own tooling. Uncomment when a project actually needs brewed Qt:
# brew "qt"
