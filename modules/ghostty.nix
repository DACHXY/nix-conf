{ inputs, ... }:
{
  flake.modules.darwin.gui =
    { config, ... }:
    {
      home-manager.users.${config.my.user.name} = {
        programs.ghostty.settings = {
          window-decoration = true;
          background-blur = true;
          background-opacity = 0.7;
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
          # CJK comes from 蘋方 (modules/fonts/pingfang.nix). Ghostty resolves
          # fallback glyphs by charset, not by lang, so the fontconfig zh rules
          # never fire in the terminal (`ghostty +show-face --string=中文` says
          # "Noto Sans Mono CJK KR" without this line). mkForce keeps stylix's
          # monospace+emoji list from being concatenated on top.
          font-family = lib.mkForce [
            "CaskaydiaCove Nerd Font Mono"
            "PingFang TC"
            "Noto Color Emoji"
          ];
          custom-shader = [
            "${ghosttyShaders}/cursor_sweep.glsl"
            "${ghosttyShaders}/ripple_cursor.glsl"
          ];

          unfocused-split-opacity = 0.4;
          desktop-notifications = true;
          background-opacity = 0.4;
          background = "#000000";
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
            "ctrl+shift+e=unbind"
            "ctrl+shift+alt+j=unbind"
          ];

          clipboard-read = "allow";
          clipboard-write = "allow";
        };
      };
    };

}
