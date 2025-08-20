{ pkgs, ... }:
{
  imports = [
    ./minimal.nix
    ../stylix.nix
    ../auto-mount.nix
    ../bluetooth.nix
    ../display-manager.nix
    ../flatpak.nix
    ../hyprland.nix
    ../obs-studio.nix
    ../plymouth.nix
    ../polkit.nix
    ../security.nix
  ];

  programs.gdk-pixbuf.modulePackages = [ pkgs.librsvg ];
}
