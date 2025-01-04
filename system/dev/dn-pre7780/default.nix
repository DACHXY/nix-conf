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
  nvidia-mode = "offload";
  # Get bus id with `lshw`
  intel-bus-id = "PCI:0:2:0";
  nvidia-bus-id = "PCI:1:0:0";
in
{
  imports = [
    inputs.home-manager.nixosModules.default
    ./hardware-configuration.nix
    ./boot.nix
    ../../modules
    (import ../../modules/nvidia.nix {
      nvidia-mode = nvidia-mode;
      intel-bus-id = intel-bus-id;
      nvidia-bus-id = nvidia-bus-id;
    })
    ../../modules/gaming.nix
    ../../modules/wireguard.nix
    ../../modules/dn-ca.nix
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
