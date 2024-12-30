{ lib, pkgs, inputs, system, nix-version, ... }:

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

  system.stateVersion = nix-version;

  home-manager = {
    backupFileExtension = "hm-backup";
    useUserPackages = true;
    useGlobalPkgs = true;
    extraSpecialArgs = { inherit inputs system nix-version; };
    users."danny" = { imports = [ ../../../home ]; };
  };
}

