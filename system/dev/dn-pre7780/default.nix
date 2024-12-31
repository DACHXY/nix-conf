{ lib, inputs, system, nix-version, ... }:

let
  cursor-size = "32";
in
{
  imports = [
    inputs.home-manager.nixosModules.default
    ./hardware-configuration.nix
    ./boot.nix
    ../../modules
    ../../modules/nvidia.nix
    ../../modules/gaming.nix
  ];

  # Overrides
  networking.hostName = lib.mkForce "dn-pre7780";

  system.stateVersion = nix-version;

  home-manager = {
    backupFileExtension = "hm-backup";
    useUserPackages = true;
    useGlobalPkgs = true;
    extraSpecialArgs = { inherit inputs system nix-version cursor-size; };
    users."danny" = { imports = [ ../../../home ]; };
  };
}

