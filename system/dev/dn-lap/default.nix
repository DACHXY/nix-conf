{
  lib,
  system,
  inputs,
  nix-version,
  git-config,
  username,
  config,
  ...
}:

let
  hyprcursor-size = "32";
  xcursor-size = "24";
  nvidia-offload-enabled = config.hardware.nvidia.prime.offload.enable;
  device-name = "dn-lap";
in
{
  imports = [
    inputs.home-manager.nixosModules.default
    ./hardware-configuration.nix
    ./boot.nix
    ../../modules
    ../../modules/wireguard.nix
    ../../modules/dn-ca.nix
    ../../modules/gaming.nix
  ];

  # Overrides
  networking.hostName = lib.mkForce device-name;

  system.stateVersion = nix-version;
  home-manager = {
    backupFileExtension = "hm-backup";
    extraSpecialArgs = {
      inherit
        inputs
        system
        nix-version
        xcursor-size
        hyprcursor-size
        git-config
        username
        nvidia-offload-enabled
        device-name
        ;
    };
    users."${username}" = {
      imports = [ ../../../home ];
    };
  };
}
