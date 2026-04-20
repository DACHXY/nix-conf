{
  self,
  inputs,
  config,
  pkgs,
  helper,
  lib,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) system;
  inherit (lib)
    mkIf
    ;
  cfg = config.systemConf;
  stateVersion = "25.11";
in
{
  # ==== System ==== #
  networking = {
    inherit (cfg) domain;
    hostName = cfg.hostname;
  };

  system.stateVersion = stateVersion;

  programs.hyprland.enable = cfg.windowManager == "hyprland";
  programs.niri.enable = cfg.windowManager == "niri";
  programs.mango.enable = cfg.windowManager == "mango";

  # ==== Home Manager ==== #
  home-manager = mkIf cfg.enableHomeManager {
    backupFileExtension = "backup-hm";
    useUserPackages = true;
    useGlobalPkgs = true;
    extraSpecialArgs = {
      inherit
        helper
        inputs
        system
        self
        ;
      inherit (cfg) username hostname;
    };
    sharedModules = [
      inputs.mango.hmModules.mango
      inputs.hyprland.homeManagerModules.default
      inputs.caelestia-shell.homeManagerModules.default
      inputs.sops-nix.homeManagerModules.default
      inputs.zen-browser.homeModules.twilight
      inputs.nvf.homeManagerModules.default
      inputs.noctalia.homeModules.default
      inputs.niri-nfsm.homeModules.default
    ];
    users.${cfg.username} = {
      home = {
        homeDirectory = "/home/${cfg.username}";
        stateVersion = stateVersion;
      };
      programs.home-manager.enable = true;

      home.file.".face" = mkIf (cfg.face != null) {
        source = cfg.face;
      };
    };
  };

}
