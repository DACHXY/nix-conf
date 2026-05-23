{
  flake.modules.nixos.base = {pkgs, ...}: {
    programs.nix-ld = {
      libraries = with pkgs;[
        openssl
        zlib
      ];
    };
  };

  flake.modules.darwin.gui = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [
     nixd
    ];
  };

  flake.modules.homeManager.zed =
    { lib, pkgs, ... }:
    {
      programs.zed-editor = {
        enable = true;
        enableMcpIntegration = false;
        installRemoteServer = true;
        extraPackages = with pkgs; [ nixd nixfmt ];

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
                    "-"= "project_panel::ToggleFocus";
                    "ctrl-h"= "workspace::ActivatePaneLeft";
                    "ctrl-j"= "workspace::ActivatePaneDown";
                    "ctrl-k"= "workspace::ActivatePaneUp";
                    "ctrl-l"= "workspace::ActivatePaneRight";
                    "space n"= "workspace::ToggleLeftDock";
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
          # Load flake.nix
          # load_direnv = "shell_hook";

          languages = {
            "Nix" = {
              formatter.external = {
                command= "nixfmt";
                arguments = ["--quiet" "--"];
              };
              language_servers = [ "nixd" "!nil" ];
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
