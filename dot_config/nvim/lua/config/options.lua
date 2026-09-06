-- Options are automatically loaded before lazy plugins
-- Everything not set here follows LazyVim defaults.

local opt = vim.opt

-- House C++ style: 4-space indents (LazyVim defaults to 2).
opt.shiftwidth = 4
opt.tabstop = 4

-- Intentionally NOT set here (already LazyVim defaults):
--   opt.smartcase = true           -- LazyVim sets ignorecase + smartcase
--   opt.clipboard = "unnamedplus"  -- LazyVim syncs with the system clipboard
