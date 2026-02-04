{
  pkgs,
  config,
  inputs,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (pkgs.stdenv.hostPlatform) system;
  inherit (config.systemConf) username;
in
{
  config = mkIf config.programs.hyprland.enable {
    programs.hyprland = {
      withUWSM = false;
      package = inputs.hyprland.packages."${system}".hyprland;
      portalPackage = inputs.hyprland.packages.${system}.xdg-desktop-portal-hyprland;
    };

    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      WLR_NO_HARDWARE_CURSORS = "1";
    };

    environment.systemPackages = (
      with pkgs;
      [
        pyprland
        hyprsunset
        hyprpicker
        hyprshot
      ]
    );

    nix = {
      settings = {
        substituters = [ "https://hyprland.cachix.org" ];
        trusted-public-keys = [
          "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        ];
      };
    };

    home-manager.users."${username}" = {
      imports = [ ../../home/user/hyprland.nix ];
    };
  };
}
