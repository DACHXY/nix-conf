{
  lib,
  system,
  inputs,
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
    ../../modules/wireguard.nix
  ];

  # Overrides
  networking.hostName = lib.mkForce "dn-lap";
  programs.steam.enable = lib.mkForce false;

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
        ;
    };
    users."${username}" = {
      imports = [ ../../../home ];
    };
  };
}
