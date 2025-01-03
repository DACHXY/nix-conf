{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    polkit
    polkit_gnome
  ];
  # polkit-gnome execution is handled by Hyprland exec.nix
  # as hyprland do not cooperate with graphical-session.target
  services.gnome.gnome-keyring.enable = true;
}
