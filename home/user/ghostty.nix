{
  inputs,
  pkgs,
  lib,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) system;
  inherit (lib) mkDefault;

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
    package = inputs.ghostty.packages.${system}.default;
    clearDefaultKeybinds = false;
    settings = {
      custom-shader = [
        "${ghosttyShaders}/cursor_sweep.glsl"
        "${ghosttyShaders}/ripple_cursor.glsl"
      ];

      unfocused-split-opacity = 0.85;
      desktop-notifications = true;
      background-opacity = mkDefault 0.6;
      background-blur = 20;

      wait-after-command = false;
      shell-integration = "detect";
      window-theme = "dark";

      confirm-close-surface = false;
      window-decoration = false;

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
}
