{ lib, pkgs, inputs, ... }:

{
  imports = [
    inputs.home-manager.nixosModules.default
    ./hardware-configuration.nix
    ../../modules
    ../../modules/nvidia.nix
    ./boot.nix
  ];

  # Overrides
  networking.hostName = lib.mkForce "dn-pre7780";

  system.stateVersion = "24.11";
  home-manager = {
    backupFileExtension = "backup";
    extraSpecialArgs = { inherit inputs; };
    users = { "danny" = import ../../../home; };
  };
}

