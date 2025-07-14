{
  pkgs,
  lib,
  inputs,
  system,
  osConfig,
  ...
}:
{
  programs.poetry = {
    enable = true;
    settings = {
      virtualenvs.create = true;
      virtualenvs.in-project = true;
    };
  };

  home.packages =
    with pkgs;
    [
      # Terminal
      inputs.ghostty.packages.${system}.default

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
        [

        ]
    );

  home.sessionVariables = lib.mkIf osConfig.programs.steam.enable {
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
  };
}
