{pkgs, ...}: let
  keybinds = import ./binds;
  plugins = import ./plugins {inherit pkgs;};
in {
  programs.nvf = {
    enable = true;
    settings = {
      vim = {
        package = pkgs.neovim-unwrapped;
        lazy.plugins = plugins;

        viAlias = false;
        vimAlias = true;
        useSystemClipboard = true;

        keymaps = keybinds;

        lsp = {
          formatOnSave = true;
          lspkind.enable = false;
          lightbulb.enable = true;
          lspsaga.enable = false;
          trouble.enable = true;
          lspSignature.enable = true;
          otter-nvim.enable = true;
          lsplines.enable = true;
          nvim-docs-view.enable = true;
        };

        debugger = {
          nvim-dap = {
            enable = true;
            ui.enable = true;
          };
        };

        theme = {
          enable = true;
          name = "tokyonight";
          style = "night";
        };

        snippets = {
          luasnip.enable = true;
        };

        binds = {
          whichKey.enable = true;
          cheatsheet.enable = true;
        };

        git = {
          enable = true;
          gitsigns.enable = true;
          gitsigns.codeActions.enable = false;
        };

        minimap = {
          codewindow.enable = true;
        };

        projects = {
          project-nvim.enable = true;
        };

        notes = {
          todo-comments.enable = true;
          mind-nvim.enable = true;
        };

        tabline = {
          nvimBufferline.enable = true;
        };

        utility = {
          icon-picker.enable = true;
          surround.enable = true;
          diffview-nvim.enable = true;
          motion = {
            hop.enable = true;
            leap.enable = true;
            precognition.enable = false;
          };

          images = {
            image-nvim = {
              enable = true;
              setupOpts = {
                backend = "kitty";
                processor = "magick_cli";
                integrations = {
                  markdown = {
                    enable = true;
                    downloadRemoteImages = true;
                  };
                };
              };
            };
          };
        };

        filetree.neo-tree = {
          enable = true;
          setupOpts = {
            filesystem = {
              bind_to_cwd = false;
              follow_current_file.enabled = true;
              use_libuv_file_watcher = true;
            };
            window.mappings = {
              "<space>" = "none";
              "l" = "open";
              "h" = "close_node";
            };
            default_component_configs = {
              indent = {
                with_expanders = true;
                expander_collapsed = "";
                expander_expanded = "";
                expander_highlight = "NeoTreeExpander";
              };
              git_status = {
                symbols = {
                  unstaged = "󰄱";
                  staged = "󰱒";
                };
              };
            };
          };
        };

        ui = {
          borders.enable = true;
          colorizer.enable = true;
          illuminate.enable = true;
          noice.enable = true;
          breadcrumbs = {
            enable = true;
            navbuddy.enable = true;
          };

          smartcolumn = {
            enable = true;
            setupOpts.custom_colorcolumn = {
              nix = "110";
              ruby = "120";
              java = "130";
              go = ["90" "130"];
            };
          };
          fastaction.enable = true;
        };

        statusline.lualine = {
          enable = true;
          theme = "tokyonight";
        };

        telescope.enable = true;
        autocomplete.nvim-cmp.enable = true;
        autopairs.nvim-autopairs.enable = true;
        treesitter.context.enable = true;

        languages = {
          enableLSP = true;
          enableFormat = true;
          enableTreesitter = true;
          enableExtraDiagnostics = true;

          nix.enable = true;
          markdown.enable = true;
          bash.enable = true;
          clang.enable = true;
          css.enable = true;
          html.enable = true;
          sql.enable = true;
          java.enable = true;
          kotlin.enable = true;
          ts.enable = true;
          go.enable = true;
          lua.enable = true;
          zig.enable = true;
          python.enable = true;
          typst.enable = true;
          rust = {
            enable = true;
            crates.enable = true;
          };
        };

        visuals = {
          nvim-scrollbar.enable = true;
          nvim-web-devicons.enable = true;
          nvim-cursorline.enable = true;
          cinnamon-nvim.enable = true;
          fidget-nvim.enable = true;
          highlight-undo.enable = true;
          indent-blankline.enable = true;

          # Fun
          cellular-automaton.enable = false;
        };

        comments = {
          comment-nvim.enable = true;
        };

        presence = {
          neocord.enable = true;
        };
      };
    };
  };
}
