{
  pkgs,
  config,
  username,
  inputs,
  ...
}:
let
  caskaydia = {
    name = "CaskaydiaCove Nerd Font Mono";
    package = pkgs.nerd-fonts.caskaydia-cove;
  };

  sf-pro-display-bold = pkgs.callPackage ../../pkgs/fonts/sf-pro-display-bold { };
  # dfkai-sb = pkgs.callPackage ../../pkgs/fonts/dfkai-sb { src = inputs.kaiu-font; };
in
{
  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-material-dark-medium.yaml";
    polarity = "dark";

    fonts = {
      serif = config.stylix.fonts.monospace;

      sansSerif = config.stylix.fonts.monospace;

      monospace = caskaydia;

      emoji = {
        package = pkgs.noto-fonts-emoji;
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
      noto-fonts-emoji
      liberation_ttf
      # dfkai-sb
      sf-pro-display-bold
    ];

    fontDir.enable = true;
  };

  home-manager.users."${username}" = {
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
    };
  };
}
