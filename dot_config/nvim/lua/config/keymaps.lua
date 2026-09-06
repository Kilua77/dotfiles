-- Keymaps are automatically loaded on the VeryLazy event
-- Everything not mapped here follows LazyVim defaults.

local map = vim.keymap.set

-- Save file (ported habit). NOTE: this shadows LazyVim's <leader>w window
-- group; windows remain reachable with <C-h>/<C-j>/<C-k>/<C-l> (LazyVim
-- mappings), and <C-s> also saves. Delete this map to restore the group.
map("n", "<leader>w", ":w!<CR>", { desc = "Save File", silent = true })

-- Search prefix (ported habit). Space is also the leader (as in the VS Code
-- Vim emulation), so leader sequences still win via longest-match and a lone
-- Space falls through to "/" once `timeoutlen` (300 ms in LazyVim) expires.
map("n", "<Space>", "/", { silent = true })

-- Clear search highlighting (LazyVim also clears it with <Esc>).
map("n", "<leader><CR>", "<cmd>nohl<CR>", { desc = "Clear Search Highlight", silent = true })

-- Scroll 3 lines at a time and keep the cursor on the middle line (ported habit).
map("n", "<C-e>", "3<C-e>M", { silent = true })
map("n", "<C-y>", "3<C-y>M", { silent = true })
