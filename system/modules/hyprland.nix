{
  pkgs,
  config,
  inputs,
  lib,
  ...
}:
let
  inherit (lib) mkIf;

  hyprlandEnabled = config.programs.hyprland.enable;
in
{
  programs.hyprland = {
    enable = config.systemConf.hyprland.enable;
    withUWSM = false;
    package = inputs.hyprland.packages."${pkgs.system}".hyprland;
    portalPackage = inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland;
  };

  xdg.portal = mkIf hyprlandEnabled {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ];
  };

  environment.sessionVariables = mkIf hyprlandEnabled {
    NIXOS_OZONE_WL = "1";
    WLR_NO_HARDWARE_CURSORS = "1";
  };

  environment.systemPackages = mkIf hyprlandEnabled (
    with pkgs;
    [
      pyprland
      hyprsunset
      hyprpicker
      hyprshot
      kitty

      # qt5.qtwayland
      # qt6.qtwayland
      wlogout
      wl-clipboard

      # Util
      grim
      slurp
    ]
  );

  nix = mkIf hyprlandEnabled {
    settings = {
      substituters = [ "https://hyprland.cachix.org" ];
      trusted-public-keys = [
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      ];
    };
  };
}
