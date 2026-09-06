-- Autocmds are automatically loaded on the VeryLazy event

-- Strip trailing whitespace before writing C++ and Python sources.
-- `keeppatterns` keeps the search history clean; the view and the '[ / ']
-- marks are saved and restored so neither the cursor nor last-change
-- motions move because of the rewrite.
vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("user-strip-trailing-whitespace", { clear = true }),
  pattern = { "*.py", "*.cpp", "*.hpp", "*.h", "*.cc" },
  callback = function()
    local view = vim.fn.winsaveview()
    local mark_open = vim.fn.getpos("'[")
    local mark_close = vim.fn.getpos("']")
    vim.cmd([[keeppatterns %s/\s\+$//e]])
    vim.fn.setpos("'[", mark_open)
    vim.fn.setpos("']", mark_close)
    vim.fn.winrestview(view)
  end,
})
