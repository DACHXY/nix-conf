{
  lib,
  inputs,
  system,
  nix-version,
  git-config,
  username,
  ...
}:

let
  hyprcursor-size = "32";
  xcursor-size = "24";
in
{
  imports = [
    inputs.home-manager.nixosModules.default
    ./hardware-configuration.nix
    ./boot.nix
    ../../modules
    ../../modules/nvidia.nix
    ../../modules/gaming.nix
    ../../modules/wireguard.nix
  ];

  # Overrides
  networking.hostName = lib.mkForce "dn-pre7780";

  system.stateVersion = nix-version;

  home-manager = {
    backupFileExtension = "hm-backup";
    useUserPackages = true;
    useGlobalPkgs = true;
    extraSpecialArgs = {
      inherit
        inputs
        system
        nix-version
        xcursor-size
        hyprcursor-size
        git-config
        username
        ;
    };
    users."${username}" = {
      imports = [ ../../../home ];
    };
  };
}
