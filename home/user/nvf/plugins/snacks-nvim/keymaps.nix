let
  keyList = [
    {
      key = "<leader><space>";
      action = "picker.smart()";
      desc = "Smart Find Files";
    }
    {
      key = "<leader>/";
      action = "picker.grep()";
      desc = "Live Grep";
    }
    {
      key = "<leader>ss";
      action = "picker.lsp_symbols()";
      desc = "Find symbols";
    }
    {
      key = "<leader>sS";
      action = "picker.lsp_workspace_symbols()";
      desc = "Find symbols (Workspace)";
    }
    # Grep
    {
      key = "<leader>sb";
      action = "picker.lines()";
      desc = "Buffer Lines";
    }
    {
      key = "<leader>sB";
      action = "picker.grep_buffers()";
      desc = "Grep Open Buffers";
    }
    {
      key = "<leader>sw";
      action = "picker.grep_word()";
      desc = "Visual selection or word";
      mode = [
        "n"
        "x"
      ];
    }
    {
      key = ''<leader>s"'';
      action = "picker.registers()";
      desc = "Registers";
    }
    {
      key = "<leader>sd";
      action = "picker.diagnostics()";
      desc = "Diagnostics";
    }
    {
      key = "<leader>sD";
      action = "picker.diagnostics_buffer()";
      desc = "Buffer Diagnostics";
    }
    {
      key = "gd";
      action = "picker.lsp_definitions()";
      desc = "Goto Definition";
    }
    {
      key = "gD";
      action = "picker.lsp_declarations()";
      desc = "Goto Declaration";
    }
    {
      key = "gr";
      action = "picker.lsp_references()";
      desc = "References";
    }
    {
      key = "gI";
      action = "picker.lsp_implementations()";
      desc = "Goto Implementation";
    }
    {
      key = "gy";
      action = "picker.lsp_type_definitions()";
      desc = "Goto T[y]pe Definition";
    }
    {
      key = "<leader>st";
      action = "picker.todo_comments()";
      desc = "Todo";
    }
    {
      key = "<leader>sT";
      action = ''picker.todo_comments({ keywords = { "TODO", "FIX", "FIXME" } })'';
      desc = "Todo/Fix/Fixme";
    }

    # === Git === #
    {
      key = "<leader>gd";
      action = "picker.git_diff()";
      desc = "Git Diff";
    }
    {
      key = "<leader>gl";
      action = "picker.git_log()";
      desc = "Git Log";
    }
    {
      key = "<leader>gs";
      action = "picker.git_stash()";
      desc = "Git Stash";
    }
  ];

  mkLuaKeyMap =
    {
      key,
      action,
      desc ? "",
      mode ? [ "n" ],
    }:
    {
      inherit key desc mode;
      action = "function() Snacks.${action} end";
      lua = true;
      nowait = true;
      unique = true;
    };
in
map (x: mkLuaKeyMap x) keyList
