{ pkgs, ... }:

{
  programs.hyprland = { enable = true; };

  environment.systemPackages = with pkgs; [
    hyprsunset
    hyprpaper
    hyprpicker
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
    rofi
    waybar
  ];

  nix = {
    settings = {
      warn-dirty = false;
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      substituters = [ "https://hyprland.cachix.org" ];

      trusted-public-keys = [
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      ];
    };
  };

}
