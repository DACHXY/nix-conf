local pattern = "[^:]+:(%d+):(%d+):(%w+):(.+)"
local groups = { "lnum", "col", "code", "message" }

return {
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        -- verilog = { "verible" },
      },
      linters = {
        verible = {
          cmd = "verible-verilog-lint",
          stdin = false,
          args = { "--rules_config_search" },
          stream = nil,
          ignore_exitcode = false,
          env = nil,
          parser = require("lint.parser").from_pattern(pattern, groups),
        },
      },
    },
  },
}
