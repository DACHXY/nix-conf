[
  {
    key = "<leader>z";
    mode = ["n"];
    desc = "Toggle Zen Mode";
    action = "function() Snacks.zen() end";
    lua = true;
  }
  {
    key = "<leader>Z";
    mode = ["n"];
    desc = "Toggle Zoom";
    action = "function() Snacks.zen.zoom() end";
    lua = true;
  }
  {
    key = "<leader>.";
    mode = ["n"];
    desc = "Toggle Scratch Buffer";
    action = "function() Snacks.scratch() end";
    lua = true;
  }
  {
    key = "<leader>S";
    mode = ["n"];
    desc = "Select Scratch Buffer";
    action = "function() Snacks.scratch.select() end";
    lua = true;
  }
  {
    key = "<leader>n";
    mode = ["n"];
    desc = "Notification History";
    action = "function() Snacks.notifier.show_history() end";
    lua = true;
  }
  {
    key = "<leader>bd";
    mode = ["n"];
    desc = "Delete Buffer";
    action = "function() Snacks.bufdelete() end";
    lua = true;
  }
  {
    key = "<leader>cR";
    mode = ["n"];
    desc = "Rename File";
    action = "function() Snacks.rename.rename_file() end";
    lua = true;
  }
  {
    key = "<leader>gB";
    mode = ["n" "v"];
    desc = "Git Browse";
    action = "function() Snacks.gitbrowse() end";
    lua = true;
  }
  {
    key = "<leader>gb";
    mode = ["n"];
    desc = "Git Blame Line";
    action = "function() Snacks.git.blame_line() end";
    lua = true;
  }
  {
    key = "<leader>gf";
    mode = ["n"];
    desc = "Lazygit Current File History";
    action = "function() Snacks.lazygit.log_file() end";
    lua = true;
  }
  {
    key = "<leader>gg";
    mode = ["n"];
    desc = "Lazygit";
    action = "function() Snacks.lazygit() end";
    lua = true;
  }
  {
    key = "<leader>gl";
    mode = ["n"];
    desc = "Lazygit Log (cwd)";
    action = "function() Snacks.lazygit.log() end";
    lua = true;
  }
  {
    key = "<leader>un";
    mode = ["n"];
    desc = "Dismiss All Notifications";
    action = "function() Snacks.notifier.hide() end";
    lua = true;
  }
  {
    key = "<c-/>";
    mode = ["n"];
    desc = "Toggle Terminal";
    action = "function() Snacks.terminal() end";
    lua = true;
  }
  {
    key = "<c-_>";
    mode = ["n"];
    desc = "which_key_ignore";
    action = "function() Snacks.terminal() end";
    lua = true;
  }
  {
    key = "]]";
    mode = ["n" "t"];
    desc = "Next Reference";
    action = "function() Snacks.words.jump(vim.v.count1) end";
    lua = true;
  }
  {
    key = "[[";
    mode = ["n" "t"];
    desc = "Prev Reference";
    action = "function() Snacks.words.jump(-vim.v.count1) end";
    lua = true;
  }
]
