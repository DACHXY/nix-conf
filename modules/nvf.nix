{ inputs, config, ... }:
{
  flake.modules.nixos.nvf = nixosArgs: {
    home-manager.users.${nixosArgs.config.my.user.name}.imports = [
      config.flake.modules.homeManager.nvf
    ];
  };

  flake.modules.darwin.nvf = darwinArgs: {
    home-manager.users.${darwinArgs.config.my.user.name}.imports = [
      config.flake.modules.homeManager.nvf
    ];
  };

  flake.modules.homeManager.nvf =
    {
      config,
      osConfig,
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib.generators) mkLuaInline;
      inherit (lib) optionalString;
      inherit (builtins) concatStringsSep;
      inherit (pkgs.stdenv.hostPlatform) isDarwin;

      marks-nvim = pkgs.vimUtils.buildVimPlugin {
        name = "marks-nvim";
        src = inputs.marks-nvim;
      };

      yaziOpenDir = config.programs.nvf.settings.vim.utility.yazi-nvim.setupOpts.open_for_directories;
    in
    {
      home.sessionVariables = {
        EDITOR = "nvim";
      };

      imports = [
        inputs.nvf.homeManagerModules.default
      ];

      home.packages = with pkgs; [
        ripgrep
        (rust-bin.stable.latest.default.override {
          extensions = [ "rust-src" ];
        })
      ];
      programs.nvf = {
        enable = true;
        settings = {
          vim = {
            enableLuaLoader = true;
            vimAlias = true;
            luaConfigPre = ''
              ${optionalString yaziOpenDir "vim.g.loaded_netrwPlugin = 1"}
            '';

            treesitter.grammars = with pkgs.vimPlugins.nvim-treesitter-parsers; [
              dockerfile
              caddy
              nginx
              vue
              scss
            ];

            extraPackages = with pkgs; [
              nixfmt
              hadolint
              fd
              imagemagick
              ghostscript
            ];

            clipboard = {
              enable = true;
              providers = {
                wl-copy.enable = if isDarwin then false else true;
              };
              registers = "unnamedplus";
            };

            extraPlugins = with pkgs.vimPlugins; {
              transparent = {
                package = transparent-nvim;
                setup =
                  let
                    clearFg = map (x: ''vim.api.nvim_set_hl(0, "${x}", { fg = "NONE", bg = "NONE"})'') [
                      "TabLineFill"
                    ];
                  in
                  # lua
                  ''
                    require("transparent").setup({
                      extra_groups = {
                        "NormalFloat",
                        "NvimTreeNormal",
                        "TreesitterContext",
                        "FloatBorder",
                        "FoldColumn",
                        "Folded",
                        "BlinkCmpMenu",
                        "BlinkCmpBorder",
                        "BlinkCmpKind",
                        "WarningMsg",
                        "ColorColumn",
                        "ErrorMsg",
                        "BlinkCmpMenuBorder",
                        "FzfLuaBackdrop",
                        "VertSplit",
                        "Pmenu",
                        "PmenuSbar",
                        "DiffText",
                        "DiffViewNormal",
                        "CursorColumn",
                        "QuickFixLine",
                        "Error",
                        "NoiceScrollbar"
                      },
                    })
                    require("transparent").clear_prefix("NeoTree")
                    require("transparent").clear_prefix("GitGutter")
                    require("transparent").clear_prefix("BufferLine")

                    ${concatStringsSep "\n" clearFg}
                  '';
              };
              marks = {
                package = marks-nvim;
                setup = ''
                  require("marks").setup {}
                '';
              };
            };

            keymaps =
              let
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
                snacksKeyList = [
                  {
                    key = "<leader><space>";
                    action = "picker.files()";
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
                snacksKeymap = map (x: mkLuaKeyMap x) snacksKeyList;
              in
              [
                # === Buffer === #
                {
                  key = "<Leader>bo";
                  mode = [ "n" ];
                  action = ":BufferLineCloseOther<CR>";
                  desc = "Close other buffer";
                }

                # === General Control === #
                # Save file
                {
                  key = "<C-s>";
                  mode = [
                    "n"
                    "i"
                    "v"
                  ];
                  action = "<C-\\><C-n>:w<CR>";
                  desc = "Save file";
                }
                {
                  key = "<S-Tab>";
                  mode = [ "i" ];
                  action = "<C-d>";
                  desc = "Shift left";
                }
                {
                  key = "<Leader>n";
                  mode = [ "n" ];
                  action = ":NoiceAll<CR>";
                  nowait = true;
                  desc = "Notifications";
                }
                {
                  key = "<ESC><ESC>";
                  mode = [ "n" ];
                  action = ":noh<CR>";
                  desc = "Clear highlight";
                }

                # === Tab === #
                {
                  key = ">";
                  mode = [ "v" ];
                  action = ">gv";
                  silent = true;
                  desc = "Shift right";
                }
                {
                  key = "<";
                  mode = [ "v" ];
                  action = "<gv";
                  silent = true;
                  desc = "Shift left";
                }

                # === Terminal === #
                {
                  key = "<C-/>";
                  mode = [ "t" ];
                  action = "<C-\\><C-n>:ToggleTerm<CR>";
                }
                {
                  key = "<C-_>";
                  mode = [ "t" ];
                  action = "<C-\\><C-n>:ToggleTerm<CR>";
                }
                {
                  key = "<C-_>";
                  mode = [ "n" ];
                  action = ":ToggleTerm<CR>";
                }
                {
                  key = "<ESC><ESC>";
                  mode = [ "t" ];
                  action = "<C-\\><C-n>";
                }
                {
                  key = "<C-j>";
                  mode = [
                    "n"
                    "t"
                  ];
                  action = "<C-\\><C-n><C-w>j";
                  nowait = true;
                }
                {
                  key = "<C-k>";
                  mode = [
                    "n"
                    "t"
                  ];
                  action = "<C-\\><C-n><C-w>k";
                  nowait = true;
                }
                {
                  key = "<C-l>";
                  mode = [
                    "n"
                    "t"
                  ];
                  action = "<C-\\><C-n><C-w>l";
                  nowait = true;
                }
                {
                  key = "<C-h>";
                  mode = [
                    "n"
                    "t"
                  ];
                  action = "<C-\\><C-n><C-w>h";
                  nowait = true;
                }
                # New Term
                {
                  key = "<Leader>tn";
                  mode = [ "n" ];
                  action = ":TermNew<CR>";
                  nowait = true;
                  desc = "Spawn new terminal";
                }
                # Select Term
                {
                  key = "<Leader>tt";
                  mode = [ "n" ];
                  action = ":TermSelect<CR>";
                  nowait = true;
                  desc = "Select terminal";
                }

                # Send current selection to Term
                {
                  key = "<Leader>ts";
                  mode = [ "v" ];
                  action = ":ToggleTermSendVisualSelection<CR>";
                  nowait = true;
                  desc = "Send current selection to terminal";
                }

                # === Fold (nvim-ufo) === #
                {
                  key = "zR";
                  mode = [ "n" ];
                  action = ''
                    require("ufo").openAllFolds
                  '';
                  lua = true;
                }
                {
                  key = "zM";
                  mode = [ "n" ];
                  action = ''
                    require("ufo").closeAllFolds
                  '';
                  lua = true;
                }
              ]
              ++ snacksKeymap;

            autocmds = [
              {
                event = [ "TextYankPost" ];
                callback =
                  mkLuaInline
                    # lua
                    ''
                      function()
                        vim.highlight.on_yank({ higroup = "IncSearch", timeout = 150 })
                      end
                    '';
                desc = "Highlight yanked";
              }
              {
                event = [ "BufWritePost" ];
                callback =
                  mkLuaInline
                    # lua
                    ''
                      function(args)
                        local bufname = vim.api.nvim_buf_get_name(args.buf)
                        local info = string.format("Saved %s", vim.fn.fnamemodify(bufname, ":t"))
                        require("fidget").notify(info, vim.log.levels.INFO)
                      end
                    '';
                desc = "Fidget notify file saved";
              }
            ];

            globals = {
              transparent_enabled = true;
            };

            options = {
              foldcolumn = "0";
              foldlevel = 99;
              foldlevelstart = 99;
              foldenable = true;
              spelllang = "en,cjk";
              expandtab = true;
              tabstop = 2;
              softtabstop = 2;
              shiftwidth = 2;
              autoindent = true;
              smartindent = true;
              fillchars = "eob: ";
              wrap = false;
            };

            lsp = {
              enable = true;
              formatOnSave = true;
              otter-nvim = {
                enable = true;
                setupOpts.handle_leading_whitespace = true;
              };
              nvim-docs-view.enable = true;
              lspkind.enable = true;
              null-ls.enable = false;
              trouble = {
                enable = true;
                mappings = {
                  documentDiagnostics = "<Leader>xx";
                };
              };

              servers.nix.init_options = {
                nixos.expr =
                  # nix
                  ''(builtins.getFlake "/etc/nixos").nixosConfigurations.${osConfig.networking.hostName}.options'';
                home_manager.expr =
                  # nix
                  ''(builtins.getFlake "/etc/nixos").nixosConfigurations.${osConfig.networking.hostName}.options.home-manager.users.type.getSubOptions []'';
              };
            };

            debugger = {
              nvim-dap = {
                enable = true;
                ui.enable = true;
              };
            };

            formatter = {
              conform-nvim.enable = true;
            };

            diagnostics = {
              enable = true;
              config = {
                float.border = "rounded";
                virtual_text.format =
                  mkLuaInline
                    # lua
                    ''
                      function(diagnostic)
                        return string.format("%s (%s)", diagnostic.message, diagnostic.source)
                      end
                    '';
              };
              nvim-lint.linters_by_ft = {
                dockerfile = [ "hadolint" ];
              };
            };

            languages = {
              enableFormat = true;
              enableTreesitter = true;
              enableExtraDiagnostics = true;

              nix = {
                enable = true;
                extraDiagnostics.enable = false;
                format = {
                  type = [ "nixfmt" ];
                  enable = true;
                };
                lsp.servers = [ "nixd" ];
              };
              rust = {
                enable = true;
                lsp = {
                  enable = true;
                  opts = /* lua */ ''
                    ['rust-analyzer'] = {
                      cargo = { allFeature = true },
                      checkOnSave = true,
                      procMacro = {
                        enable = true,
                      },
                    },
                  '';
                };
              };

              assembly.enable = true;
              clang.enable = true;
              cmake.enable = true;
              make.enable = true;

              json.enable = true;
              toml.enable = true;
              jq.enable = true;
              yaml.enable = true;
              xml.enable = true;

              lua.enable = true;
              python = {
                enable = true;
                format.type = [ "ruff" ];
              };
              go.enable = true;

              markdown = {
                enable = true;
                extensions = {
                  render-markdown-nvim.enable = false;
                  markview-nvim.enable = true;
                };
              };
              bash.enable = true;
              glsl.enable = true;
              sql.enable = true;

              typescript = {
                enable = true;
                format.type = [ "prettierd" ];
                extensions.ts-error-translator = {
                  enable = true;
                  setupOpts = {
                    auto_attach = true;
                  };
                };
              };
              vue.enable = true;
              html.enable = true;
              css = {
                enable = true;
                format.type = [ "prettierd" ];
              };
            };

            visuals = {
              nvim-web-devicons.enable = true;
              nvim-cursorline.enable = true;
              fidget-nvim = {
                enable = true;
                setupOpts.notification = {
                  window = {
                    border = "none";
                    winblend = 100;
                  };
                };
              };
              highlight-undo.enable = true;
              indent-blankline.enable = true;
            };

            autopairs.nvim-autopairs.enable = true;

            autocomplete = {
              blink-cmp = {
                enable = true;
                friendly-snippets.enable = true;
                setupOpts = {
                  completion = {
                    menu.border = "rounded";
                    documentation.window.border = "rounded";
                  };
                };
              };
            };

            snippets.luasnip = {
              enable = true;
              providers = [
                "friendly-snippets"
                "blink-cmp"
                "base16"
                "lsp-signature-nvim"
                "snacks-nvim"
              ];
              setupOpts.enable_autosnippets = true;
            };

            git = {
              enable = true;
            };

            tabline = {
              nvimBufferline = {
                enable = true;
                setupOpts = {
                  options = {
                    show_close_icon = false;
                    separator_style = "thin";
                    numbers = "none";
                    indicator = {
                      style = "none";
                    };
                    diagnostic = "nvim_lsp";
                  };
                };
                mappings = {
                  closeCurrent = "<Leader>bd";
                  cycleNext = "L";
                  cyclePrevious = "H";
                };
              };
            };

            binds = {
              whichKey.enable = true;
            };

            dashboard = {
              alpha.enable = true;
            };

            notify = {
              nvim-notify = {
                enable = true;
                setupOpts.background_colour = "#020202";
              };
            };

            projects = {
              project-nvim.enable = true;
            };

            utility = {
              diffview-nvim.enable = true;
              icon-picker.enable = true;
              surround.enable = true;
              multicursors.enable = true;
              undotree.enable = true;

              yazi-nvim = {
                enable = true;
                setupOpts.open_for_directories = true;
                mappings.openYaziDir = "<leader>-";
                mappings.openYazi = "<leader>e";
              };

              images = {
                image-nvim = {
                  enable = true;
                  setupOpts = {
                    backend = "kitty";
                  };
                };
              };

              snacks-nvim = {
                enable = true;
                setupOpts = {
                  image = {
                    enabled = true;
                    doc = {
                      enabled = true;
                    };
                    math = {
                      enabled = true;
                      latex = {
                        font_size = "Large";
                        packages = [
                          "amsmath"
                          "amssymb"
                          "amsfonts"
                          "amscd"
                          "mathtools"
                        ];
                      };
                    };
                  };
                  bigfile = {
                    enabled = true;
                  };
                  dashboard = {
                    enabled = false;
                  };
                  explorer = {
                    enabled = false;
                  };
                  indent = {
                    enabled = true;
                  };
                  input = {
                    enabled = true;
                  };
                  picker = {
                    enabled = true;
                    sources = {
                      explorer.layout.layout.position = "right";
                    };
                    formatters = {
                      file.filename_first = true;
                    };
                  };
                  notifier = {
                    enabled = true;
                  };
                  quickfile = {
                    enabled = true;
                  };
                  scope = {
                    enabled = true;
                  };
                  scroll = {
                    enabled = true;
                  };
                  statuscolumn = {
                    enabled = false;
                  };
                  words = {
                    enabled = true;
                  };
                };

              };
            };

            notes = {
              todo-comments.enable = true;
            };

            terminal = {
              toggleterm = {
                enable = true;
                lazygit.enable = true;
                mappings = {
                  open = "<C-/>";
                };
                setupOpts.direction = "float";
                setupOpts.winbar.name_formatter =
                  mkLuaInline
                    # lua
                    ''
                      function(term)
                        return "  " .. term.id
                      end
                    '';
              };
            };

            ui = {
              noice = {
                enable = true;
                setupOpts = {
                  routes = [
                    # Hide neo-tree notification
                    {
                      filter = {
                        event = "notify";
                        kind = "info";
                        any = [
                          { find = "hidden"; }
                        ];
                      };
                    }
                    # Hide Save
                    {
                      filter = {
                        event = "msg_show";
                        kind = "bufwrite";
                      };
                      opts = {
                        skip = true;
                      };
                    }
                    {
                      filter = {
                        event = "msg_show";
                        any = [
                          { find = "written"; }
                        ];
                      };
                    }
                  ];
                };
              };
              colorizer.enable = true;
              fastaction.enable = true;
              nvim-ufo = {
                enable = true;
                setupOpts = {
                  fold_virt_text_handler =
                    mkLuaInline
                      # lua
                      ''
                        function(virtText, lnum, endLnum, width, truncate)
                            local newVirtText = {}
                            local suffix = (' 󰁂 %d '):format(endLnum - lnum)
                            local sufWidth = vim.fn.strdisplaywidth(suffix)
                            local targetWidth = width - sufWidth
                            local curWidth = 0
                            for _, chunk in ipairs(virtText) do
                                local chunkText = chunk[1]
                                local chunkWidth = vim.fn.strdisplaywidth(chunkText)
                                if targetWidth > curWidth + chunkWidth then
                                    table.insert(newVirtText, chunk)
                                else
                                    chunkText = truncate(chunkText, targetWidth - curWidth)
                                    local hlGroup = chunk[2]
                                    table.insert(newVirtText, {chunkText, hlGroup})
                                    chunkWidth = vim.fn.strdisplaywidth(chunkText)
                                    -- str width returned from truncate() may less than 2nd argument, need padding
                                    if curWidth + chunkWidth < targetWidth then
                                        suffix = suffix .. (' '):rep(targetWidth - curWidth - chunkWidth)
                                    end
                                    break
                                end
                                curWidth = curWidth + chunkWidth
                            end
                            table.insert(newVirtText, {suffix, 'MoreMsg'})
                            return newVirtText
                        end
                      '';

                  provider_selector =
                    mkLuaInline
                      # lua
                      ''
                        function(bufnr, filetype, buftype)
                            return {'treesitter', 'indent'}
                        end
                      '';
                };
              };
              borders = {
                enable = true;
                plugins = {
                  lspsaga.enable = true;
                  fastaction.enable = true;
                  lsp-signature.enable = true;
                  which-key.enable = true;
                };
              };
            };

            mini.surround = {
              enable = true;
              setupOpts = {
                mappings = {
                  add = "gsa";
                  delete = "gsd";
                  find = "gsf";
                  find_left = "gsF";
                  highlight = "gsh";
                  replace = "gsr";
                  suffix_last = "";
                  suffix_next = "";
                };
                silent = true;
              };
            };

            statusline = {
              lualine = {
                enable = true;
                activeSection = {
                  a = lib.mkForce [
                    ''
                      {
                        "mode",
                        icons_enabled = true,
                        separator = {
                          left = "",
                          right = ""
                        },
                      }
                    ''
                    ''
                      {
                        "",
                        draw_empty = true,
                        separator = { left = '', right = '' }
                      }
                    ''
                  ];
                  b = lib.mkForce [
                    ''
                      {
                        "filetype",
                        colored = true,
                        icon_only = true,
                        icon = { align = 'left' }
                      }
                    ''
                    ''
                      {
                        "filename",
                        symbols = {modified = ' ', readonly = ' '},
                        separator = { left = '', right = ''}
                      }
                    ''
                    ''
                      {
                        "",
                        draw_empty = true,
                        separator = { left = '', right = '' }
                      }
                    ''
                  ];
                  c = lib.mkForce [
                    # lua
                    ''
                       {
                          "diff",
                          colored = false,
                          diff_color = {
                            -- Same color values as the general color option can be used here.
                            added    = 'DiffAdd',    -- Changes the diff's added color
                            modified = 'DiffChange', -- Changes the diff's modified color
                            removed  = 'DiffDelete', -- Changes the diff's removed color you
                          },
                          symbols = {added = '+', modified = '~', removed = '-'}, -- Changes the diff symbols
                          separator = {right = ''}
                      }
                    ''
                  ];
                  x = lib.mkForce [
                    # lua
                    ''
                      {
                        -- Lsp server name
                        function()
                          local buf_ft = vim.bo.filetype
                          local excluded_buf_ft = { toggleterm = true, NvimTree = true, ["neo-tree"] = true, TelescopePrompt = true }

                          if excluded_buf_ft[buf_ft] then
                            return ""
                            end

                          local bufnr = vim.api.nvim_get_current_buf()
                          local clients = vim.lsp.get_clients({ bufnr = bufnr })

                          if vim.tbl_isempty(clients) then
                            return "No Active LSP"
                          end

                          local active_clients = {}
                          for _, client in ipairs(clients) do
                            table.insert(active_clients, client.name)
                          end

                          return table.concat(active_clients, ", ")
                        end,
                        icon = ' ',
                        separator = {left = ''},
                      }
                    ''
                    # lua
                    ''
                      {
                        -- Recording Status
                        function()
                          local reg = vim.fn.reg_recording()
                          if reg == "" then return "" end
                          return "@" .. reg
                        end,
                      }
                    ''
                    # lua
                    ''
                      {
                        "diagnostics",
                        sources = {'nvim_lsp', 'nvim_diagnostic', 'nvim_diagnostic', 'vim_lsp', 'coc'},
                        symbols = {error = '󰅙  ', warn = '  ', info = '  ', hint = '󰌵 '},
                        colored = true,
                        update_in_insert = false,
                        always_visible = false,
                        diagnostics_color = {
                          color_error = { fg = 'red' },
                          color_warn = { fg = 'yellow' },
                          color_info = { fg = 'cyan' },
                        },
                      }
                    ''
                  ];
                  y = lib.mkForce [
                    ''
                      {
                        "",
                        draw_empty = true,
                        separator = { left = '', right = '' }
                      }
                    ''
                    ''
                      {
                        'searchcount',
                        maxcount = 999,
                        timeout = 120,
                        separator = {left = ''}
                      }
                    ''
                    ''
                      {
                        "branch",
                        icon = ' •',
                        separator = {left = ''}
                      }
                    ''
                  ];
                  z = lib.mkForce [
                    ''
                      {
                        "",
                        draw_empty = true,
                        separator = { left = '', right = '' }
                      }
                    ''
                    ''
                      {
                        "progress",
                        separator = {left = ''}
                      }
                    ''
                    ''
                      {"location"}
                    ''
                    ''
                      {
                        "fileformat",
                        color = {fg='black'},
                        symbols = {
                          unix = '', -- e843
                          dos = '',  -- e70f
                          mac = '',  -- e711
                        }
                      }
                    ''
                  ];
                };
                componentSeparator = {
                  left = "";
                  right = "";
                };
                sectionSeparator = {
                  left = "";
                  right = "";
                };
              };
            };
          };
        };
      };
    };
}
