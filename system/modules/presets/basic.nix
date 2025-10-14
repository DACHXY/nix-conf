{ pkgs, ... }:
{
  imports = [
    ./minimal.nix
    ../stylix.nix
    ../auto-mount.nix
    ../bluetooth.nix
    ../display-manager.nix
    ../flatpak.nix
    ../obs-studio.nix
    ../plymouth.nix
    ../polkit.nix
    ../security.nix
    ../hyprland.nix
  ];

  programs.gdk-pixbuf.modulePackages = [ pkgs.librsvg ];
}
