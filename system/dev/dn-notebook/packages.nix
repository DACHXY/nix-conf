{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    age
    bat
    btop
    coreutils

    fzf
    ffmpeg

    iftop
    imagemagick

    killall
    wget

    podman
    podman-compose
    podman-tui
    podman-desktop
  ];
}
