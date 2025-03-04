return {
  {
    "brianhuster/live-preview.nvim",
    dependencies = {
      -- You can choose one of the following pickers
      "ibhagwan/fzf-lua",
    },
    cmd = "LivePreview",
    keys = { { "<leader>cp", "<cmd>LivePreview close<cr><cmd>LivePreview start<cr>", desc = "Live Preview" } },
    opts = true,
    enabled = true,
  },
}
