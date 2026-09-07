# Neovim — lean LazyVim

Lean LazyVim on purpose, kept close to upstream defaults: VS Code is the primary editor.
This tree is symlinked to `~/.config/nvim` by `script/bootstrap` (the `.symlink` suffix on the directory).
The plugin lockfile lives in `stdpath("state")/lazy-lock.json`, outside this repo, so plugin updates never dirty the dotfiles git tree.
C++ extras (clangd extra + cmake-tools) are wired in `init.lua` and `lua/plugins/coding-cpp.lua`.
