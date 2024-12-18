return {
  {
    "mfussenegger/nvim-dap",
    config = function() end,
  },
  {
    "linux-cultist/venv-selector.nvim",
    dependencies = { "neovim/nvim-lspconfig", "nvim-telescope/telescope.nvim", "mfussenegger/nvim-dap" },
    opts = {
      name = { "venv", ".venv" },
      parents = 2,
      auto_refresh = true,
    },
    event = "VeryLazy",
  },
}
