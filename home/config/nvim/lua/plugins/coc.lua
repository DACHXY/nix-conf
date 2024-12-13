return {
  { "neoclide/coc.nvim", branch = "release" },
  { "yaegassy/coc-volar", dependencies = "neoclide/coc.nvim", build = "yarn install --frozen-lockfile" },
}
