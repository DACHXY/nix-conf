{
  osConfig,
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  inherit (builtins) concatStringsSep;
  inherit (lib.generators) mkLuaInline;
  inherit (lib) optionalString;

  suda-nvim = pkgs.vimUtils.buildVimPlugin {
    name = "vim-suda";
    src = pkgs.fetchFromGitHub {
      owner = "lambdalisue";
      repo = "vim-suda";
      rev = "9adda7d195222d4e2854efb2a88005a120296c47";
      hash = "sha256-46sy3rAdOCULVt1RkIoGdweoV3MqQaB33Et9MrxI6Lk=";
    };
  };

  marks-nvim = pkgs.vimUtils.buildVimPlugin {
    name = "marks-nvim";
    src = inputs.marks-nvim;
  };

  yaziOpenDir = config.programs.nvf.settings.vim.utility.yazi-nvim.setupOpts.open_for_directories;
in
{
  imports = [
    ./plugins/snacks-nvim
    ./plugins/lualine
    ./plugins/leetcode
    ./extra-lsp.nix
  ];

  home.packages = with pkgs; [
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
        extraPackages = with pkgs; [
          nixfmt
        ];

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
          suda = {
            package = suda-nvim;
          };
          marks = {
            package = marks-nvim;
            setup = ''
              require("marks").setup {}
            '';
          };
        };

        keymaps = [
          # === Buffer === #
          {
            key = "<Leader>bo";
            mode = [ "n" ];
            action = ":BufferLineCloseOther<CR>";
            desc = "Close other buffer";
          }
          {
            key = "<Leader>bS";
            mode = [ "n" ];
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
        ];

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
          conform-nvim = {
            enable = true;
            # setupOpts = {
            #   formatters_by_ft = {
            #     nix = [ "nixfmt" ];
            #   };
            # };
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
          yaml.enable = true;
          rust = {
            enable = true;
            lsp = {
              enable = true;
              opts = ''
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
          nix = {
            enable = true;
            extraDiagnostics.enable = false;
            format = {
              type = [ "nixfmt" ];
              enable = true;
            };
            lsp.servers = [ "nixd" ];
          };
          sql.enable = true;
          clang.enable = true;
          ts = {
            enable = true;
            format.type = [ "prettierd" ];
            extensions = {
              ts-error-translator.enable = true;
            };
          };
          python.enable = true;
          markdown = {
            enable = true;
            extensions = {
              render-markdown-nvim.enable = false;
              markview-nvim.enable = true;
            };
          };
          html.enable = true;
          lua.enable = true;
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
      };
    };
  };
}
