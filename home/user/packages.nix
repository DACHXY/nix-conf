{
  pkgs,
  lib,
  inputs,
  system,
  osConfig,
  ...
}:
let
  inherit (lib) optional;
in
{
  programs.poetry = {
    enable = true;
    settings = {
      virtualenvs.create = true;
      virtualenvs.in-project = true;
    };
  };

  programs.ghostty = {
    enable = true;
    installBatSyntax = true;
    enableFishIntegration = true;
    package = inputs.ghostty.packages.${system}.default;
    settings = {
      font-family = "CaskaydiaCove Nerd Font Mono";
      font-size = 15;
      theme = "Espresso";
      unfocused-split-opacity = 0.85;
      desktop-notifications = false;

      wait-after-command = false;
      shell-integration = "detect";
      window-theme = "dark";

      confirm-close-surface = false;
      window-decoration = false;

      mouse-hide-while-typing = true;

      keybind = [ "ctrl+shift+zero=toggle_tab_overview" ];

      clipboard-read = "allow";
      clipboard-write = "allow";
    };
  };

  home.packages =
    with pkgs;
    [
      obsidian

      # Discord
      vesktop

      # Dev stuff
      (python3.withPackages (python-pkgs: [
        python-pkgs.pip
        python-pkgs.requests
        python-pkgs.weasyprint
      ]))

      # Work stuff
      libreoffice-qt
      pandoc
      texliveSmall

      # Bluetooth
      blueberry

      # Downloads
      qbittorrent

      # Utils
      cava
      papirus-folders
      inkscape

      # PDF Preview
      poppler
      trash-cli

      # File Manager
      nemo

      # Thumbnail
      ffmpegthumbnailer

      thunderbird
    ]
    ++ (
      if osConfig.programs.steam.enable then
        [
          steam-run
          protonup
        ]
      else
        [ ]
    );

  home.sessionVariables = lib.mkIf osConfig.programs.steam.enable {
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
  };
}
