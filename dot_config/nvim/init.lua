-- Neovim entry point: bootstrap lazy.nvim, then load LazyVim with the
-- personal config from lua/config and lua/plugins.
--
-- VS Code remains the primary editor; this is the lean, terminal-only second
-- editor (quick edits, remote machines) and stays close to LazyVim defaults.

-- Bootstrap lazy.nvim (standard snippet from the lazy.nvim docs).
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local out = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo(
      vim.split(out, "\n"),
      true,
      { err = true, title = "Error cloning lazy.nvim" }
    )
  end
end
vim.opt.rtp:prepend(lazypath)

-- mapleader is intentionally NOT set here: LazyVim's default leader is
-- <Space>, which is the desired layout and matches the user's VS Code Vim
-- configuration (leader = Space).

require("lazy").setup({
  spec = {
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    -- import any extras modules here
    { import = "lazyvim.plugins.extras.lang.clangd" },
    { import = "plugins" },
  },
  defaults = {
    -- Every plugin is lazy-loaded unless its spec explicitly opts out.
    lazy = true,
  },
  -- Built-in colorscheme used while plugins install on first launch, before
  -- LazyVim's default scheme (a plugin) is available.
  install = { colorscheme = { "habamax" } },
  -- No update checks on startup; run :Lazy check/update manually instead.
  checker = { enabled = false },
  -- Kept out of ~/.config so `chezmoi apply` never fights with lazy.nvim
  -- over it; a reference copy may be committed to the repo manually.
  lockfile = vim.fn.stdpath("state") .. "/lazy-lock.json",
})
