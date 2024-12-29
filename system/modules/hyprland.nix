{ pkgs, inputs, system, ... }:

{
  programs.hyprland = {
    enable = true;
  };

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    xdgOpenUsePortal = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk pkgs.xdg-desktop-portal-hyprland ];
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    WLR_NO_HARDWARE_CURSORS = "1";
  };

  environment.systemPackages = with pkgs; [
    pyprland
    # hyprlock
    hyprcursor
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
    rofi-wayland-unwrapped
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
