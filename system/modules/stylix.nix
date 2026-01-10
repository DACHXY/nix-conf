{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (config.systemConf) username;
  inherit (lib) mkForce;

  caskaydia = {
    name = "CaskaydiaCove Nerd Font Mono";
    package = pkgs.nerd-fonts.caskaydia-cove;
  };

  sf-pro-display-bold = pkgs.callPackage ../../pkgs/fonts/sf-pro-display-bold { };
in
{
  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-material-dark-medium.yaml";
    polarity = "dark";
    enableReleaseChecks = false;

    fonts = {
      serif = config.stylix.fonts.monospace;

      sansSerif = config.stylix.fonts.monospace;

      monospace = caskaydia;

      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };

      sizes = {
        terminal = 15;
        desktop = 14;
        popups = 12;
      };
    };
  };

  fonts = {
    packages = with pkgs; [
      font-awesome
      jetbrains-mono
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
      liberation_ttf
      sf-pro-display-bold
    ];

    fontDir.enable = true;
  };

  home-manager.users."${username}" = {
    stylix.enableReleaseChecks = false;

    stylix.targets.neovim.transparentBackground = {
      main = true;
      numberLine = true;
      signColumn = true;
    };
    stylix.targets = {
      swaync.enable = false;
      zen-browser.enable = false;
      waybar.enable = false;
      hyprlock.enable = false;
      hyprland.enable = false;
      rofi.enable = false;
      nvf = {
        enable = true;
        transparentBackground = true;
      };
      helix = {
        enable = true;
        transparent = mkForce true;
      };
    };
  };
}
