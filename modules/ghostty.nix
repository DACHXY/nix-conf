{ inputs, ... }:
{
  flake.modules.darwin.gui =
    { config, ... }:
    {
      home-manager.users.${config.my.user.name} = {
        programs.ghostty.settings = {
          window-decoration = true;
          background-blur = true;
          font-size = 17;
        };
      };
    };

  flake.modules.homeManager.gui =
    {
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib) mkDefault;
      inherit (pkgs.stdenv.hostPlatform) system isDarwin;

      ghosttyShaders = pkgs.fetchFromGitHub {
        owner = "sahaj-b";
        repo = "ghostty-cursor-shaders";
        rev = "main";
        hash = "sha256-ruhEqXnWRCYdX5mRczpY3rj1DTdxyY3BoN9pdlDOKrE=";
      };
    in
    {
      programs.ghostty = {
        enable = true;
        installBatSyntax = true;
        enableFishIntegration = true;
        package = if isDarwin then pkgs.ghostty-bin else inputs.ghostty.packages.${system}.default;
        clearDefaultKeybinds = false;
        settings = {
          custom-shader = [
            "${ghosttyShaders}/cursor_sweep.glsl"
            "${ghosttyShaders}/ripple_cursor.glsl"
          ];

          unfocused-split-opacity = 0.65;
          desktop-notifications = true;
          background-opacity = 0.5;
          background-blur = mkDefault false; # For wm
          background-opacity-cells = true;

          wait-after-command = false;
          shell-integration = "detect";
          window-theme = "dark";

          confirm-close-surface = false;
          window-decoration = mkDefault false;

          mouse-hide-while-typing = true;

          keybind = [
            "ctrl+shift+zero=toggle_tab_overview"
            "ctrl+shift+9=reload_config"
            "ctrl+shift+o=unbind"
          ];

          clipboard-read = "allow";
          clipboard-write = "allow";
        };
      };
    };

}
