{
  pkgs,
  inputs,
  ...
}:
{
  programs.hyprland = {
    enable = true;
    withUWSM = false;
    package = inputs.hyprland.packages."${pkgs.system}".hyprland;
    portalPackage = inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland;
  };

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ];
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    WLR_NO_HARDWARE_CURSORS = "1";
  };

  environment.systemPackages = with pkgs; [
    pyprland
    hyprsunset
    hyprpicker
    hyprshot
    kitty

    # Notification
    libnotify
    swaynotificationcenter

    qt5.qtwayland
    qt6.qtwayland
    wlogout
    wl-clipboard
    waybar

    # Util
    grim
    slurp
  ];

  nix = {
    settings = {
      substituters = [ "https://hyprland.cachix.org" ];
      trusted-public-keys = [
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      ];
    };
  };
}
