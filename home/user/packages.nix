{
  pkgs,
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

  home.packages = with pkgs; [
    obsidian
    discord

    # Work stuff
    libreoffice-qt

    # Downloads
    qbittorrent

    # Utils
    cava
    papirus-folders
    inkscape
    trash-cli

    # File Manager
    nemo

    thunderbird

    # Thumbnail
    ffmpegthumbnailer

    md2html
  ];
}
