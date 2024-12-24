{ lib, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules
    ../../modules/nvidia.nix
    ./boot.nix
    inputs.home-manager.nixosModules.default
  ];

  # Overrides
  networking.hostName = "dn-pre7780";

  system.stateVersion = "24.11";
  home-manager = {
    backupFileExtension = "backup";
    extraSpecialArgs = { inherit inputs; };
    users = { "danny" = import ../home; };
  };
}

