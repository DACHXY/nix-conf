let
  directions = ["h" "j" "k" "l"];
  generateMappings = direction: {
    key = "<C-${direction}>";
    mode = ["n"];
    silent = true;
    action = "<C-w>${direction}";
  };
  naviMappings = map generateMappings directions;
  resizeStep = "2";
  resizeMappings = [
    {
      key = "<C-Left>";
      mode = ["n"];
      silent = true;
      action = "<cmd>vertical resize -${resizeStep}<CR>";
    }
    {
      key = "<C-Right>";
      mode = ["n"];
      silent = true;
      action = "<cmd>vertical resize +${resizeStep}<CR>";
    }
    {
      key = "<C-Up>";
      mode = ["n"];
      silent = true;
      action = "<cmd>resize +${resizeStep}<CR>";
    }
    {
      key = "<C-Down>";
      mode = ["n"];
      silent = true;
      action = "<cmd>resize -${resizeStep}<CR>";
    }
  ];
  moveLineMappings = [
    {
      key = "<A-j>";
      mode = ["n"];
      silent = true;
      action = "<cmd>m .+1<CR>==";
    }
    {
      key = "<A-k>";
      mode = ["n"];
      silent = true;
      action = "<cmd>m .-2<CR>==";
    }
  ];
  saveMappings = [
    # Save File
    {
      key = "<C-s>";
      mode = ["n"];
      silent = true;
      action = "<cmd>w<CR><ESC>";
      noremap = true;
    }
    {
      key = "<C-s>";
      mode = ["i"];
      silent = true;
      action = "<cmd>w<CR><ESC>";
      noremap = true;
    }
    {
      key = "<C-s>";
      mode = ["x"];
      silent = true;
      action = "<cmd>w<CR><ESC>";
      noremap = true;
    }
    {
      key = "<C-s>";
      mode = ["s"];
      silent = true;
      action = "<cmd>w<CR><ESC>";
      noremap = true;
    }
  ];
  generalMappings = [
    {
      key = "<S-h>";
      mode = ["n"];
      silent = true;
      action = "<cmd>bprevious<CR>";
    } # Prev Buffer
    {
      key = "<S-l>";
      mode = ["n"];
      silent = true;
      action = "<cmd>bnext<CR>";
    } # Next Buffer
    {
      key = "[b";
      mode = ["n"];
      silent = true;
      action = "<cmd>bprevious<CR>";
    } # Prev Buffer
    {
      key = "]b";
      mode = ["n"];
      silent = true;
      action = "<cmd>bnext<CR>";
    } # Next Buffer
    {
      key = "<leader>bb";
      mode = ["n"];
      silent = true;
      action = "<cmd>buffer #<CR>";
    } # Switch to Other Buffer
    {
      key = "<leader>`";
      mode = ["n"];
      silent = true;
      action = "<cmd>buffer #<CR>";
    } # Switch to Other Buffer
    {
      key = "<leader>bd";
      mode = ["n"];
      silent = true;
      action = "<cmd>bd<CR>";
    } # Delete Buffer
    {
      key = "<leader>bo";
      mode = ["n"];
      silent = true;
      action = "<cmd>bufdo bd<CR>";
    } # Delete Other Buffers
    {
      key = "<leader>bD";
      mode = ["n"];
      silent = true;
      action = "<cmd>bd | :q<CR>";
    } # Delete Buffer and Window
    {
      key = "<esc>";
      mode = ["i" "n" "s"];
      silent = true;
      action = "<cmd>noh<CR>";
    } # Escape and Clear hlsearch
    {
      key = "<leader>ur";
      mode = ["n"];
      silent = true;
      action = "<Cmd>nohlsearch<Bar>diffupdate<Bar>normal! <C-L><CR>";
      desc = "Redraw / Clear hlsearch / Diff Update";
    } # Redraw / Clear hlsearch / Diff Update
    {
      key = "n";
      mode = ["n" "x" "o"];
      silent = true;
      action = "n";
    } # Next Search Result
    {
      key = "N";
      mode = ["n" "x" "o"];
      silent = true;
      action = "N";
    } # Prev Search Result
    {
      key = "<C-s>";
      mode = ["i" "x" "n" "s"];
      silent = true;
      action = "<cmd>w<CR>";
    } # Save File
    {
      key = "<leader>K";
      mode = ["n"];
      silent = true;
      action = "<cmd>norm! K<cr>";
    } # Keywordprg
    {
      key = "gco";
      mode = ["n"];
      silent = true;
      action = "o<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>";
    } # Add Comment Below
    {
      key = "gcO";
      mode = ["n"];
      silent = true;
      action = "O<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>";
    } # Add Comment Above
    {
      key = "<leader>fn";
      mode = ["n"];
      silent = true;
      action = "<cmd>enew<CR>";
    } # New File
    {
      key = "<leader>xl";
      mode = ["n"];
      silent = true;
      action = "<cmd>lopen<CR>";
    } # Location List
    {
      key = "<leader>xq";
      mode = ["n"];
      silent = true;
      action = "<cmd>copen<CR>";
    } # Quickfix List
    {
      key = "[q";
      mode = ["n"];
      silent = true;
      lua = true;
      action = "vim.cmd.cprev";
    } # Previous Quickfix
    {
      key = "]q";
      mode = ["n"];
      silent = true;
      lua = true;
      action = "vim.cmd.cnext";
    } # Next Quickfix
    {
      key = "<leader>cf";
      mode = ["n" "v"];
      silent = true;
      action = "<cmd>normal! gq<CR>";
    } # Format
    {
      key = "<leader>cd";
      mode = ["n"];
      silent = true;
      action = "<cmd>LspDiagnostics<CR>";
    } # Line Diagnostics
    {
      key = "]d";
      mode = ["n"];
      silent = true;
      action = "<cmd>lnext<CR>";
    } # Next Diagnostic
    {
      key = "[d";
      mode = ["n"];
      silent = true;
      action = "<cmd>lprevious<CR>";
    } # Prev Diagnostic
    {
      key = "]e";
      mode = ["n"];
      silent = true;
      action = "<cmd>lnext<CR>";
    } # Next Error
    {
      key = "[e";
      mode = ["n"];
      silent = true;
      action = "<cmd>lprevious<CR>";
    } # Prev Error
    {
      key = "]w";
      mode = ["n"];
      silent = true;
      action = "<cmd>lnext<CR>";
    } # Next Warning
    {
      key = "[w";
      mode = ["n"];
      silent = true;
      action = "<cmd>lprevious<CR>";
    } # Prev Warning
    {
      key = "<leader>uf";
      mode = ["n"];
      silent = true;
      action = "<cmd>ToggleAutoFormat<CR>";
    } # Toggle Auto Format (Global)
    {
      key = "<leader>uF";
      mode = ["n"];
      silent = true;
      action = "<cmd>ToggleAutoFormatBuffer<CR>";
    } # Toggle Auto Format (Buffer)
    {
      key = "<leader>us";
      mode = ["n"];
      silent = true;
      action = "<cmd>setlocal spell!<CR>";
    } # Toggle Spelling
    {
      key = "<leader>uw";
      mode = ["n"];
      silent = true;
      action = "<cmd>set wrap!<CR>";
    } # Toggle Wrap
    {
      key = "<leader>uL";
      mode = ["n"];
      silent = true;
      action = "<cmd>set relativenumber!<CR>";
    } # Toggle Relative Number
    {
      key = "<leader>ud";
      mode = ["n"];
      silent = true;
      action = "<cmd>LspDiagnosticsToggle<CR>";
    } # Toggle Diagnostics
    {
      key = "<leader>ul";
      mode = ["n"];
      silent = true;
      action = "<cmd>set number!<CR>";
    } # Toggle Line Numbers
    {
      key = "<leader>uc";
      mode = ["n"];
      silent = true;
      action = "<cmd>set conceallevel=3<CR>";
    } # Toggle Conceal Level
    {
      key = "<leader>uA";
      mode = ["n"];
      silent = true;
      action = "<cmd>set showtabline=2<CR>";
    } # Toggle Tabline
    {
      key = "<leader>uT";
      mode = ["n"];
      silent = true;
      action = "<cmd>TSToggleHighlight<CR>";
    } # Toggle Treesitter Highlight
    {
      key = "<leader>ub";
      mode = ["n"];
      silent = true;
      action = "<cmd>set background=dark<CR>";
    } # Toggle Dark Background
    {
      key = "<leader>uD";
      mode = ["n"];
      silent = true;
      action = "<cmd>ToggleDimming<CR>";
    } # Toggle Dimming
    {
      key = "<leader>ua";
      mode = ["n"];
      silent = true;
      action = "<cmd>ToggleAnimations<CR>";
    } # Toggle Animations
    {
      key = "<leader>ug";
      mode = ["n"];
      silent = true;
      action = "<cmd>IndentGuidesToggle<CR>";
    } # Toggle Indent Guides
    {
      key = "<leader>uS";
      mode = ["n"];
      silent = true;
      action = "<cmd>SmoothScrollToggle<CR>";
    } # Toggle Smooth Scroll
    {
      key = "<leader>dpp";
      mode = ["n"];
      silent = true;
      action = "<cmd>ToggleProfiler<CR>";
    } # Toggle Profiler
    {
      key = "<leader>dph";
      mode = ["n"];
      silent = true;
      action = "<cmd>ToggleProfilerHighlights<CR>";
    } # Toggle Profiler Highlights
    {
      key = "<leader>uh";
      mode = ["n"];
      silent = true;
      action = "<cmd>ToggleInlayHints<CR>";
    } # Toggle Inlay Hints
    {
      key = "<leader>gb";
      mode = ["n"];
      silent = true;
      action = "<cmd>GitBlame<CR>";
    } # Git Blame Line
    {
      key = "<leader>gB";
      mode = ["n" "x"];
      silent = true;
      action = "<cmd>GitBrowseOpen<CR>";
    } # Git Browse (open)
    {
      key = "<leader>gY";
      mode = ["n" "x"];
      silent = true;
      action = "<cmd>GitBrowseCopy<CR>";
    } # Git Browse (copy)
    {
      key = "<leader>qq";
      mode = ["n"];
      silent = true;
      action = "<cmd>qa!<CR>";
    } # Quit All
    {
      key = "<leader>ui";
      mode = ["n"];
      silent = true;
      action = "<cmd>InspectPos<CR>";
    } # Inspect Pos
    {
      key = "<leader>uI";
      mode = ["n"];
      silent = true;
      action = "<cmd>InspectTree<CR>";
    } # Inspect Tree
    {
      key = "<leader>L";
      mode = ["n"];
      silent = true;
      action = "<cmd>LazyVimChangelog<CR>";
    } # LazyVim Changelog
    {
      key = "<c-_>";
      mode = ["n" "t"];
      silent = true;
      action = "<nop>";
    } # which_key_ignore
    {
      key = "<leader>w";
      mode = ["n"];
      silent = true;
      action = "<cmd>windows<CR>";
    } # Windows
    {
      key = "<leader>-";
      mode = ["n"];
      silent = true;
      action = "<cmd>split<CR>";
    } # Split Window Below
    {
      key = "<leader>|";
      mode = ["n"];
      silent = true;
      action = "<cmd>vsplit<CR>";
    } # Split Window Right
    {
      key = "<leader>wd";
      mode = ["n"];
      silent = true;
      action = "<cmd>close<CR>";
    } # Delete Window
    {
      key = "<leader>wm";
      mode = ["n"];
      silent = true;
      action = "<cmd>ZoomModeToggle<CR>";
    } # Toggle Zoom Mode
    {
      key = "<leader>uZ";
      mode = ["n"];
      silent = true;
      action = "<cmd>ZoomModeToggle<CR>";
    } # Toggle Zoom Mode
    {
      key = "<leader>uz";
      mode = ["n"];
      silent = true;
      action = "<cmd>ZenModeToggle<CR>";
    } # Toggle Zen Mode
    {
      key = "<leader><tab>l";
      mode = ["n"];
      silent = true;
      action = "<cmd>tabprevious<CR>";
    } # Last Tab
    {
      key = "<leader><tab>o";
      mode = ["n"];
      silent = true;
      action = "<cmd>tabnew<CR>";
    } # Close Other Tabs
    {
      key = "<leader><tab>f";
      mode = ["n"];
      silent = true;
      action = "<cmd>tabfirst<CR>";
    } # First Tab
    {
      key = "<leader><tab><tab>";
      mode = ["n"];
      silent = true;
      action = "<cmd>tabnew<CR>";
    } # New Tab
    {
      key = "<leader><tab>]";
      mode = ["n"];
      silent = true;
      action = "<cmd>tabnext<CR>";
    } # Next Tab
    {
      key = "<leader><tab>d";
      mode = ["n"];
      silent = true;
      action = "<cmd>tabclose<CR>";
    } # Close Tab
    {
      key = "<leader><tab>[";
      mode = ["n"];
      silent = true;
      action = "<cmd>tabprevious<CR>";
    } # Previous Tab
  ];
in
  naviMappings ++ resizeMappings ++ moveLineMappings ++ saveMappings ++ generalMappings
