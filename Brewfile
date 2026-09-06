# Brewfile -- Homebrew bundle for the macOS side of these dotfiles.
#
# Applied automatically by .chezmoiscripts/run_onchange_after_10-brew-bundle.sh.tmpl
# via `brew bundle`. That script embeds the sha256 of this file, so any edit
# here re-runs `brew bundle` on the next `chezmoi apply`.
# Manual run (from the repo root): brew bundle --file=Brewfile
#
# Linux equivalents live in .chezmoiscripts/run_onchange_after_11-apt-packages.sh.tmpl.

# --- Casks (GUI applications and fonts) --------------------------------------

cask "visual-studio-code"
cask "ghostty"
cask "font-jetbrains-mono-nerd-font"

# --- Formulae (CLI tools) ----------------------------------------------------

# Shell and terminal
brew "chezmoi"
brew "zsh"
brew "tmux"
brew "starship"
brew "zoxide"
brew "fzf"
brew "eza"
brew "bat"
brew "ripgrep"
brew "fd"
brew "git-delta"
brew "lazygit"
brew "gh"
brew "jq"

# Editor
brew "neovim"

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
