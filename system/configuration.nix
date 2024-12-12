{ lib, pkgs, inputs, ... }:

{
  imports = [ ./hardware-configuration.nix ./modules inputs.home-manager.nixosModules.default ];

  system.stateVersion = "24.11";
  home-manager = {
    backupFileExtension = "backup";
    extraSpecialArgs = { inherit inputs; };
    users = {
       "danny" = import ../home;
    };
  };
}

