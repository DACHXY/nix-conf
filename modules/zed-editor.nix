{
  flake.modules.homeManager.zed =
    { lib, pkgs, ... }:
    {
      programs.zed-editor = {
        enable = true;
        enableMcpIntegration = false;
        installRemoteServer = true;

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
            "context" = "Workspace";
            "bindings" = {
              "space space" = "file_finder::Toggle";
            };
          }
        ];
        userSettings = {
          auto_update = false;
          vim_mode = true;
          base_keymap = "VSCode";
          hour_format = "hour24";
          # Load flake.nix
          load_direnv = "shell_hook";

          node = {
            path = lib.getExe pkgs.nodejs;
            npm_path = lib.getExe' pkgs.nodejs "npm";
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
            toolbar.title = true;
            working_directory = "current_project_directory";
          };

          lsp = {
            rust-analyzer.binary.path_lookup = true;
            nix.binary.path_lookup = true;
          };
        };
      };
    };
}
