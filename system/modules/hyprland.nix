{ config, pkgs, ... }:

{
  programs.hyprland = { enable = true; };

  environment.systemPackages = with pkgs; [
    hyprsunset
    hyprpaper
    hyprshot
    kitty

    # Notification
    libnotify
    swaynotificationcenter

    qt5.qtwayland
    qt6.qtwayland
    swayidle
    sway-audio-idle-inhibit # Prevent idle when playing audio
    swaylock-effects
    wlogout
    wl-clipboard
    wofi
    waybar
  ];
}
