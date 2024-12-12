{ config, pkgs, ... }:

{
  programs.hyprland = { enable = true; };

  environment.systemPackages = with pkgs; [
    hyprshade
    hyprpaper
    kitty
    libnotify
    mako
    qt5.qtwayland
    qt6.qtwayland
    swayidle
    swaylock-effects
    wlogout
    wl-clipboard
    wofi
    waybar
  ];
}
