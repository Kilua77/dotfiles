-- C/C++ coding extras on top of the LazyVim clangd extra (imported in
-- init.lua). The extra already pulls clangd itself, clangd_extensions.nvim
-- and sensible server flags, so nothing is repeated here.

-- NOTE on clangd flags: LazyVim's clangd extra already launches clangd with
-- --background-index, --clang-tidy and --completion-style=detailed (plus
-- --header-insertion=iwyu and --function-arg-placeholders), so no
-- lspconfig `servers.clangd` cmd override is needed.

return {
  -- CMake preset integration (:CMakeSelectConfigurePreset, :CMakeBuild, ...).
  -- `ft` makes this a working lazy spec: with `defaults.lazy = true` a spec
  -- without a load trigger would never load. plenary is a hard dependency
  -- of cmake-tools.
  {
    "Civitasv/cmake-tools.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    ft = { "c", "cpp" },
    opts = {},
  },

  -- Treesitter parsers for the C/C++ toolchain. `opts` is merged into
  -- LazyVim's treesitter spec (ensure_installed is appended, not replaced,
  -- via the spec's opts_extend).
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = { "cpp", "c", "cmake", "lua", "bash", "make" },
    },
  },
}
