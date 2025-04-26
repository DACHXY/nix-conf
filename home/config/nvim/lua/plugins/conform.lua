return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        json = { "prettierd", "prettier", stop_after_first = true },
        jsonc = { "prettierd", "prettier", stop_after_first = true },
        verilog = { "verible" },
      },
      formatters = {
        verible = {
          command = "verible-verilog-format",
          args = { "-" },
          range_args = function(self, ctx)
            return { "--lines", ctx.range.start[1] .. "-" .. ctx.range["end"][1] }
          end,
          stdin = true,
          cwd = require("conform.util").root_file({ ".git" }),
        },
      },
    },
  },
}
