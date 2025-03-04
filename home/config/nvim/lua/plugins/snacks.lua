return {
  {
    "folke/snacks.nvim",
    opts = {
      explorer = {
        enabled = true,
      },
      image = {
        enabled = true,
        math = {
          enabled = true,
        },
      },
      picker = {
        enabled = true,
        sources = {
          explorer = {
            layout = { layout = { position = "right" } },
          },
          files = {
            ignored = true,
          },
          git_files = {
            untracked = true,
          },
        },
      },
      notifier = { enabled = true },
      dashboard = {
        enabled = true,
        width = 60,
        row = nil,
        col = nil,
        preset = {
          header = [[
 ██████████     █████████     █████████  █████   █████ █████ █████ █████ █████
░░███░░░░███   ███░░░░░███   ███░░░░░███░░███   ░░███ ░░███ ░░███ ░░███ ░░███
 ░███   ░░███ ░███    ░███  ███     ░░░  ░███    ░███  ░░███ ███   ░░███ ███
 ░███    ░███ ░███████████ ░███          ░███████████   ░░█████     ░░█████
 ░███    ░███ ░███░░░░░███ ░███          ░███░░░░░███    ███░███     ░░███
 ░███    ███  ░███    ░███ ░░███     ███ ░███    ░███   ███ ░░███     ░███
 ██████████   █████   █████ ░░█████████  █████   █████ █████ █████    █████
 ░░░░░░░░░░   ░░░░░   ░░░░░   ░░░░░░░░░  ░░░░░   ░░░░░ ░░░░░ ░░░░░    ░░░░░]],
        },
      },
    },
  },
}
