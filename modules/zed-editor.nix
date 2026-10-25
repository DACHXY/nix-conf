{ config, ... }:
{
  flake.modules.nixos.base =
    { pkgs, ... }:
    {
      programs.nix-ld = {
        libraries = with pkgs; [
          openssl
          zlib
        ];
      };
    };

  flake.modules.darwin.gui =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        nixd
      ];
    };

  flake.modules.darwin.zed = darwinArgs: {
    home-manager.users.${darwinArgs.config.my.user.name}.imports = [
      config.flake.modules.homeManager.zed
    ];
  };

  flake.modules.homeManager.zed =
    { lib, pkgs, ... }:
    let
      pythonKernel = pkgs.python3.withPackages (ps: [
        ps.ipykernel
        ps.jupyter-client
        ps.numpy
        ps.matplotlib
        ps.pandas
      ]);
    in
    {
      home.file."Library/Jupyter/kernels/python3/kernel.json".text = builtins.toJSON {
        argv = [
          "${pythonKernel}/bin/python3"
          "-m"
          "ipykernel_launcher"
          "-f"
          "{connection_file}"
        ];
        display_name = "Python 3 (Nix)";
        language = "python";
        interrupt_mode = "message";
      };

      programs.zed-editor = {
        enable = true;
        enableMcpIntegration = false;
        installRemoteServer = true;
        extraPackages = with pkgs; [
          nixd
          nixfmt
          pythonKernel
        ];

        userTasks = [
          {
            label = "jupytext: notebook -> py:percent";
            command = "${pkgs.python3Packages.jupytext}/bin/jupytext";
            args = [
              "--to"
              "py:percent"
              "$ZED_FILE"
            ];
          }
          {
            label = "jupytext: py:percent -> notebook";
            command = "${pkgs.python3Packages.jupytext}/bin/jupytext";
            args = [
              "--to"
              "ipynb"
              "$ZED_FILE"
            ];
          }
        ];

        extensions = [
          "nix"
          "toml"
          "rust"
          "vue"
          "json"
          "make"
          "typescript"
          "html"
          "dockerfile"
          "aura-theme"
          "charmed-icons"
        ];
        mutableUserKeymaps = true;
        mutableUserSettings = true;
        mutableUserTasks = true;

        userKeymaps = [
          {
            context = "(vim_mode == helix_normal || vim_mode == helix_select) && !menu";
            bindings = {
              "space space" = "file_finder::Toggle";
            };
            unbind = {
              "space f" = "file_finder::Toggle";
            };
          }
          {
            context = "Editor && VimControl && !VimWaiting && !menu";
            bindings = {
              "-" = "project_panel::ToggleFocus";
              "space -" = "project_panel::ToggleFocus";
              "space e" = "project_panel::ToggleFocus";
              "space space" = "file_finder::Toggle";
              "space /" = "pane::DeploySearch";
              "space s b" = "buffer_search::Deploy";
              "space s s" = "outline::Toggle";
              "space s S" = "project_symbols::Toggle";
              "space s d" = "diagnostics::Deploy";
              "space g" = "git_panel::ToggleFocus";
              "space p" = "projects::OpenRecent";
              "g d" = "editor::GoToDefinition";
              "g D" = "editor::GoToDeclaration";
              "g r" = "editor::FindAllReferences";
              "g I" = "editor::GoToImplementation";
              "g y" = "editor::GoToTypeDefinition";
              "space m r" = "repl::Run";
              "space m l" = "repl::RunInPlace";
              "space m i" = "repl::Sessions";
              "space m s" = "repl::Interrupt";
              "space m shift-r" = "repl::Restart";
              "space m c" = "repl::ClearOutputs";
              "ctrl-h" = "workspace::ActivatePaneLeft";
              "ctrl-j" = "workspace::ActivatePaneDown";
              "ctrl-k" = "workspace::ActivatePaneUp";
              "ctrl-l" = "workspace::ActivatePaneRight";
              "space n" = "workspace::ToggleLeftDock";
            };
          }
          {
            context = "Workspace";
            bindings = {
              "ctrl-/" = "terminal_panel::Toggle";
            };
            unbind = {
              "ctrl-`" = "terminal_panel::Toggle";
            };
          }
          {
            context = "Workspace";
            bindings = {
              "ctrl-s" = "workspace::Save";
              "cmd-s" = "workspace::Save";
            };
          }
        ];
        userSettings = {
          auto_update = false;
          vim_mode = true;
          base_keymap = "VSCode";

          jupyter = {
            kernel_selections = {
              python = "python3";
            };
          };

          theme = lib.mkForce "Aura Dark";
          icon_theme = "Warm Charmed Icons";
          theme_overrides = {
            "Aura Dark" = {
              "editor.document_highlight.read_background" = "#00000000";
              "editor.document_highlight.write_background" = "#00000000";
              "border.variant" = "#15141C";
              border = "#15141C";
              "title_bar.background" = "#15141C";
              "panel.background" = "#15141C";
              "panel.focused_border" = "#4E466E";
              players = [
                {
                  cursor = "#BD9DFF";
                }
              ];
              syntax = {
                comment = {
                  font_style = "italic";
                };
                "comment.doc" = {
                  font_style = "italic";
                };
              };
            };
          };

          title_bar = {
            show_onboarding_banner = false;
            show_project_items = false;
            show_branch_name = false;
            show_user_menu = false;
            show_sign_in = false;
          };
          tab_bar = {
            show = false;
          };
          toolbar = {
            quick_actions = false;
          };
          status_bar = {
            "experimental.show" = false;
          };
          project_panel = {
            dock = "right";
            default_width = 400;
            hide_root = true;
            auto_fold_dirs = false;
            starts_open = false;
            git_status = false;
            sticky_scroll = false;
            scrollbar = {
              show = "never";
            };
            indent_guides = {
              show = "never";
            };
          };
          outline_panel = {
            default_width = 300;
            indent_guides = {
              show = "never";
            };
          };
          file_finder = {
            modal_max_width = "large";
          };
          scrollbar = {
            show = "never";
          };
          gutter = {
            min_line_number_digits = 0;
            folds = false;
            runnables = false;
          };
          indent_guides = {
            enabled = false;
          };
          multi_cursor_modifier = "cmd_or_ctrl";
          cursor_shape = "block";
          cursor_blink = false;
          selection_highlight = false;
          drag_and_drop_selection = {
            enabled = false;
          };
          seed_search_query_from_cursor = "never";
          current_line_highlight = "none";
          show_whitespaces = "none";
          tab_size = 2;
          auto_indent = false;
          auto_indent_on_paste = false;
          show_completions_on_input = false;
          show_completion_documentation = false;
          inline_code_actions = false;
          lsp_document_colors = "none";
          hover_popover_enabled = false;
          format_on_save = "off";
          autosave = {
            after_delay = {
              milliseconds = 1000;
            };
          };
          extend_comment_on_newline = false;
          horizontal_scroll_margin = 1;
          vertical_scroll_margin = 1;
          when_closing_with_no_tabs = "keep_window_open";
          close_on_file_delete = true;
          restore_on_file_reopen = false;
          restore_on_startup = "empty_tab";
          session = {
            restore_unsaved_buffers = false;
          };
          git = {
            git_gutter = "hide";
            inline_blame = {
              enabled = false;
            };
          };
          centered_layout = {
            right_padding = 0.15;
            left_padding = 0.15;
          };
          # Load flake.nix
          # load_direnv = "shell_hook";

          languages = {
            "Nix" = {
              formatter.external = {
                command = "nixfmt";
                arguments = [
                  "--quiet"
                  "--"
                ];
              };
              language_servers = [
                "nixd"
                "!nil"
              ];
            };
          };

          node = {
            path = lib.getExe pkgs.nodejs;
            npm_path = lib.getExe' pkgs.nodejs "npm";
          };

          lsp = {
            nixd.settings.diagnostic.supress = [ "sema-extra-with" ];
            nix = {
              binary = {
                path = lib.getExe pkgs.nixd;
              };
            };
          };

          terminal = {
            alternate_scroll = "off";
            blinking = "off";
            copy_on_select = false;
            env = {
              TERM = "ghostty";
            };
            dock = "bottom";
            detect_venv.on = {
              directories = [
                ".env"
                "env"
                ".venv"
                "venv"
              ];
              activate_script = "default";
            };
            font_features = null;
            font_size = null;
            line_height = "comfortable";
            option_as_meta = false;
            button = false;
            shell = "system";
            working_directory = "current_project_directory";
          };
        };
      };
    };
}
