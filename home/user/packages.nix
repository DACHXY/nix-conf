{
  pkgs,
  lib,
  inputs,
  system,
  osConfig,
  ...
}:
let
  md2html = pkgs.callPackage ../scripts/md2html.nix { };
in
{
  programs.btop = {
    enable = true;
    settings = {
      theme_background = false;
      update_ms = 1000;
    };
  };

  programs.ghostty = {
    enable = true;
    installBatSyntax = true;
    enableFishIntegration = true;
    package = inputs.ghostty.packages.${system}.default;
    settings = {
      unfocused-split-opacity = 0.85;
      desktop-notifications = false;
      background-opacity = 0.4;
      background-blur = false;

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
      # vesktop
      discord

      # Dev stuff
      (python3.withPackages (python-pkgs: [
        python-pkgs.pip
        python-pkgs.requests
      ]))

      # Work stuff
      libreoffice-qt
      pandoc

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

      md2html
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
