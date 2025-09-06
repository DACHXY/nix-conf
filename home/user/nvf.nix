{
  pkgs,
  lib,
  ...
}: let
  inherit (lib.generators) mkLuaInline;

  suda-nvim = pkgs.vimUtils.buildVimPlugin {
    name = "vim-suda";
    src = pkgs.fetchFromGitHub {
      owner = "lambdalisue";
      repo = "vim-suda";
      rev = "9adda7d195222d4e2854efb2a88005a120296c47";
      hash = "sha256-46sy3rAdOCULVt1RkIoGdweoV3MqQaB33Et9MrxI6Lk=";
    };
  };
in {
  programs.nvf = {
    enable = true;
    settings = {
      vim = {
        enableLuaLoader = true;
        clipboard = {
          enable = true;
          providers = {
            wl-copy.enable = true;
          };
          registers = "unnamedplus";
        };

        extraPlugins = with pkgs.vimPlugins; {
          transparent = {
            package = transparent-nvim;
            setup =
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
                    "ErrorMsg",
                    "BlinkCmpMenuBorder",
                    "FzfLuaBackdrop",
                    "VertSplit",
                    "Pmenu",
                    "PmenuSbar",
                    "DiffText",
                    "DiffViewNormal",
                    "CursorColumn",
                    "ColorColumn",
                    "QuickFixLine",
                    "Error",
                    "NoiceScrollbar"
                  },
                })
                require("transparent").clear_prefix("NeoTree")
                require("transparent").clear_prefix("GitGutter")
              '';
          };
          suda = {
            package = suda-nvim;
          };
        };

        keymaps = [
          # === Files === #
          # Explorer
          {
            key = "<leader>e";
            mode = ["n"];
            action = ":Neotree toggle<CR>";
            silent = true;
            desc = "Toggle file explorer";
          }
          # Fzf lua
          {
            key = "<Leader><Space>";
            silent = true;
            mode = ["n"];
            action = ":FzfLua files<CR>";
            nowait = true;
            unique = true;
            desc = "Find file";
          }
          {
            key = "<Leader>/";
            mode = ["n"];
            action = ":FzfLua live_grep<CR>";
            nowait = true;
            unique = true;
            desc = "Live grep";
          }
          # Lsp symbol document
          {
            key = "<Leader>ss";
            silent = true;
            mode = ["n"];
            action = ":FzfLua lsp_document_symbols<CR>";
            nowait = true;
            unique = true;
            desc = "Find symbols (document)";
          }
          # Lsp symbol workspace
          {
            key = "<Leader>sS";
            silent = true;
            mode = ["n"];
            action = ":FzfLua lsp_workspace_symbols<CR>";
            unique = true;
            nowait = true;
            desc = "Find symbols (workspace)";
          }

          # === Buffer === #
          {
            key = "<Leader>bo";
            mode = ["n"];
            action = ":BufferLineCloseOther<CR>";
            desc = "Close other buffer";
          }
          {
            key = "<Leader>bS";
            mode = ["n"];
            action = ":SudaWrite<CR>";
            desc = "Save file as root";
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
            mode = ["i"];
            action = "<C-d>";
            desc = "Shift left";
          }
          {
            key = "gd";
            mode = ["n"];
            action = ":FzfLua lsp_definitions<CR>";
            nowait = true;
            desc = "Go to definition";
          }
          {
            key = "gD";
            mode = ["n"];
            action = ":FzfLua lsp_declarations<CR>";
            nowait = true;
            desc = "Go to declaration";
          }
          {
            key = "gi";
            mode = ["n"];
            action = ":FzfLua lsp_implementations<CR>";
            nowait = true;
            desc = "Go to implementation";
          }
          {
            key = "gr";
            mode = ["n"];
            action = ":FzfLua lsp_references<CR>";
            nowait = true;
            desc = "List references";
          }
          {
            key = "<Leader>n";
            mode = ["n"];
            action = ":NoiceAll<CR>";
            nowait = true;
            desc = "Notifications";
          }

          # === Tab === #
          {
            key = ">";
            mode = ["v"];
            action = ">gv";
            silent = true;
            desc = "Shift right";
          }
          {
            key = "<";
            mode = ["v"];
            action = "<gv";
            silent = true;
            desc = "Shift left";
          }

          # === Terminal === #
          {
            key = "<C-/>";
            mode = ["t"];
            action = "<C-\\><C-n>:ToggleTerm<CR>";
          }
          {
            key = "<ESC><ESC>";
            mode = ["t"];
            action = "<C-\\><C-n>";
          }
          {
            key = "<C-j>";
            mode = ["n" "t"];
            action = "<C-\\><C-n><C-w>j";
            nowait = true;
          }
          {
            key = "<C-k>";
            mode = ["n" "t"];
            action = "<C-\\><C-n><C-w>k";
            nowait = true;
          }
          {
            key = "<C-l>";
            mode = ["n" "t"];
            action = "<C-\\><C-n><C-w>l";
            nowait = true;
          }
          {
            key = "<C-h>";
            mode = ["n" "t"];
            action = "<C-\\><C-n><C-w>h";
            nowait = true;
          }
          # New Term
          {
            key = "<Leader>tn";
            mode = ["n"];
            action = ":TermNew<CR>";
            nowait = true;
            desc = "Spawn new terminal";
          }
          # Select Term
          {
            key = "<Leader>tt";
            mode = ["n"];
            action = ":TermSelect<CR>";
            nowait = true;
            desc = "Select terminal";
          }
          # Send current selection to Term
          {
            key = "<Leader>ts";
            mode = ["v"];
            action = ":ToggleTermSendVisualSelection<CR>";
            nowait = true;
            desc = "Send current selection to terminal";
          }

          # === Fold (nvim-ufo) === #
          {
            key = "zR";
            mode = ["n"];
            action = ''
              require("ufo").openAllFolds
            '';
            lua = true;
          }
          {
            key = "zM";
            mode = ["n"];
            action = ''
              require("ufo").closeAllFolds
            '';
            lua = true;
          }
        ];

        autocmds = [
          {
            event = ["TextYankPost"];
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
        ];

        globals = {
          transparent_enabled = true;
        };

        vimAlias = true;

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
        };

        lsp = {
          enable = true;
          formatOnSave = true;
          otter-nvim.enable = true;
          nvim-docs-view.enable = true;
          lspkind.enable = true;
          trouble = {
            enable = true;
            mappings = {
              documentDiagnostics = "<Leader>xx";
            };
          };
        };

        debugger = {
          nvim-dap = {
            enable = true;
            ui.enable = true;
          };
        };

        diagnostics = {
          enable = true;
          config = {
            float = {
              border = "rounded";
            };
            virtual_text.format =
              mkLuaInline
              # lua
              ''
                function(diagnostic)
                  return string.format("%s (%s)", diagnostic.message, diagnostic.source)
                end
              '';
          };
        };

        languages = {
          enableFormat = true;
          enableTreesitter = true;
          enableExtraDiagnostics = true;

          bash.enable = true;
          css.enable = true;
          rust.enable = true;
          nix = {
            enable = true;
            lsp = {
              enable = true;
            };
          };
          sql.enable = true;
          clang.enable = true;
          ts.enable = true;
          python.enable = true;
          markdown.enable = true;
          html.enable = true;
          lua.enable = true;
        };

        visuals = {
          nvim-web-devicons.enable = true;
          nvim-cursorline.enable = true;
          cinnamon-nvim = {
            enable = true;
            setupOpts.keymaps = {
              basic = true;
            };
          };
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

        autopairs.nvim-autopairs.enable = true;

        autocomplete = {
          blink-cmp.enable = true;
        };

        snippets.luasnip = {
          enable = true;
          providers = ["blink-cmp"];
          setupOpts.enable_autosnippets = true;
        };

        git = {
          enable = true;
        };

        filetree = {
          neo-tree = {
            enable = true;
            setupOpts = {
              window = {
                position = "right";
                mappings = {
                  "l" = "open";
                  "h" = "close_node";
                };
              };
            };
          };
        };

        tabline = {
          nvimBufferline = {
            enable = true;
            setupOpts = {
              options = {
                show_close_icon = false;
                separator_style = "slope";
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

        fzf-lua.enable = true;

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

          images = {
            img-clip.enable = true;
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
            setupOpts.routes = [
              # Hide neo-tree notification
              {
                filter = {
                  event = "notify";
                  kind = "info";
                  any = [
                    {find = "hidden";}
                  ];
                };
              }
            ];
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
      };
    };
  };
}
