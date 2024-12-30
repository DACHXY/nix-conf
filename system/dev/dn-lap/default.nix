{ lib, system, inputs, nix-version, ... }:

{
  imports = [
    inputs.home-manager.nixosModules.default
    ./hardware-configuration.nix
    ./boot.nix
    ../../modules
  ];

  # Overrides
  networking.hostName = lib.mkForce "dn-lap";
  programs.steam.enable = lib.mkForce false;

  system.stateVersion = nix-version;
  home-manager = {
    backupFileExtension = "hm-backup";
    extraSpecialArgs = { inherit inputs system nix-version; };
    users = { "danny" = import ../../../home; };
  };
}

