{
  pkgs,
  config,
  inputs,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (config.systemConf) username;

  hyprlandEnabled = config.programs.hyprland.enable;
in
{
  programs.hyprland = {
    enable = config.systemConf.hyprland.enable;
    withUWSM = false;
    package = inputs.hyprland.packages."${pkgs.system}".hyprland;
    portalPackage = inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland;
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

  home-manager.users."${username}" = mkIf hyprlandEnabled {
    imports = [ ../../home/user/hyprland.nix ];
  };
}
