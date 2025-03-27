{
  lib,
  unstable,
  pkgs,
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
  # Get bus id with `lshw -C display`
  intel-bus-id = "PCI:0:2:0";
  nvidia-bus-id = "PCI:1:0:0";
  nvidia-offload-enabled = config.hardware.nvidia.prime.offload.enable;
  device-name = "dn-server";
  monitors = [
  ];
in
{
  imports = [
    inputs.home-manager.nixosModules.default
    ./hardware-configuration.nix
    ./boot.nix
    ./packages.nix
    ./services.nix
    ./networking.nix
    ../../modules/server-default.nix
    ../../modules/cuda.nix
    (import ../../modules/nvidia.nix {
      nvidia-mode = nvidia-mode;
      intel-bus-id = intel-bus-id;
      nvidia-bus-id = nvidia-bus-id;
    })
    # ../../modules/wine.nix
  ];

  nixpkgs.overlays = [ inputs.nix-minecraft.overlay ];

  environment.systemPackages = [
    (pkgs.ferium.overrideAttrs (
      final: prev: rec {
        cargoHash = "sha256-yedl4KQCpT7Ai1EPvwD5kzhkHesIjGVAcxKjp5k2jmI=";
        version = "4.7.0";
        src = pkgs.fetchFromGitHub {
          owner = "gorilla-devs";
          repo = prev.pname;
          rev = "v${version}";
          hash = "sha256-jj3BdaxH7ofhHNF2eu+burn6+/0bPQQZ8JfjXAFyN4A=";
        };

        cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
          inherit (final) pname src version;
          useFetchCargoVendor = true;
          hash = final.cargoHash;
        };
      }
    ))
  ];

  # Overrides
  networking.hostName = lib.mkForce device-name;

  system.stateVersion = nix-version;

  home-manager = {
    backupFileExtension = "backup";
    useUserPackages = true;
    extraSpecialArgs = {
      inherit
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
        monitors
        ;
    };
    users."${username}" = {
      imports = [
        ../../../home/server-default.nix
      ];
    };
  };
}
