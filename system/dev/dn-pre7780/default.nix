{
  lib,
  inputs,
  system,
  nix-version,
  git-config,
  username,
  config,
  ...
}:
let
  hyprcursor-size = "32";
  xcursor-size = "24";
  nvidia-mode = "offload";
  # Get bus id with `lshw`
  intel-bus-id = "PCI:0:2:0";
  nvidia-bus-id = "PCI:1:0:0";
  nvidia-offload-enabled = config.hardware.nvidia.prime.offload.enable;
  device-name = "dn-pre7780";
in
{
  imports = [
    inputs.home-manager.nixosModules.default
    ./hardware-configuration.nix
    ./boot.nix
    ../../modules
    ../../modules/cuda.nix
    (import ../../modules/nvidia.nix {
      nvidia-mode = nvidia-mode;
      intel-bus-id = intel-bus-id;
      nvidia-bus-id = nvidia-bus-id;
    })
    ../../modules/gaming.nix
    ../../modules/wireguard.nix
    ../../modules/dn-ca.nix
    (import ../../modules/wallpaper-engine.nix {
      offload = nvidia-offload-enabled;
    })
    ../../modules/wine.nix
  ];

  # Overrides
  networking.hostName = lib.mkForce device-name;

  system.stateVersion = nix-version;
  services.wallpaperEngine.enable = lib.mkForce false;

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
        nvidia-offload-enabled
        device-name
        ;
    };
    users."${username}" = {
      imports = [
        ../../../home
      ];
    };
  };
}
