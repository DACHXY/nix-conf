{
  lib,
  unstable,
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
  monitors = [ ];
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
        monitors
        unstable
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
      imports = [
        ../../../home
        ../../../home/user/music-production.nix
      ];
    };
  };

  users.users."${username}".openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILSHkPa6vmr5WBPXAazY16+Ph1Mqv9E24uLIf32oC2oH danny@phone.dn"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJSAOufpee7f8D8ONIIGU3qsN+8+DGO7BfZnEOTYqtQ5 danny@pre7780.dn"
  ];
}
