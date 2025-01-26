return {
  {
    "folke/noice.nvim",
    opts = {
      presets = {
        lsp_doc_border = true,
      },
      lsp = {
        override = {
          ["cmp.entry.get_documentation"] = true,
        },
      },
      views = {
        hover = {
          border = {
            style = "rounded",
          },
        },
        confirm = {
          border = {
            style = "rounded",
          },
        },
        popup = {
          border = {
            style = "rounded",
          },
        },
      },
    },
  },
}
