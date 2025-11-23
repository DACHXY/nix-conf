{
  pkgs,
  inputs,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) system;
  md2html = pkgs.callPackage ../scripts/md2html.nix { };
  ghosttyShaders = pkgs.fetchFromGitHub {
    owner = "sahaj-b";
    repo = "ghostty-cursor-shaders";
    rev = "main";
    hash = "sha256-ruhEqXnWRCYdX5mRczpY3rj1DTdxyY3BoN9pdlDOKrE=";
  };
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
      custom-shader = [
        "${ghosttyShaders}/cursor_sweep.glsl"
        "${ghosttyShaders}/ripple_cursor.glsl"
      ];

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

      keybind = [
        "ctrl+shift+zero=toggle_tab_overview"
        "ctrl+shift+e=unbind"
        "ctrl+shift+o=unbind"
      ];

      clipboard-read = "allow";
      clipboard-write = "allow";
    };
  };

  home.packages = with pkgs; [
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

    thunderbird

    # Thumbnail
    ffmpegthumbnailer

    md2html
  ];
}
