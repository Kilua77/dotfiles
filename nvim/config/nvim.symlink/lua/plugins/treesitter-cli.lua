-- tree-sitter CLI resolution on old-glibc machines (RHEL 9: glibc 2.34).
--
-- nvim-treesitter (main branch) compiles every parser through the
-- tree-sitter CLI (>= 0.26.1). Every official prebuilt of that CLI is
-- built on ubuntu-24.04 runners and needs GLIBC >= 2.35, so on RHEL 9
-- mason's copy dies with "version `GLIBC_2.39' not found" at every
-- parser install — and mason PREPENDS its bin/ to PATH, so that broken
-- binary is the one `executable("tree-sitter")` finds (LazyVim then
-- considers it present and never replaces it).
--
-- local/build.sh source-builds a working CLI into ~/.local/bin/tree-
-- sitter (rustup + cargo install --locked, glibc of the host). Appending
-- mason's bin/ instead of prepending lets the userland copy win; mason
-- keeps filling the gaps for everything else.

return {
  {
    "mason-org/mason.nvim",
    opts = { PATH = "append" },
  },
}
