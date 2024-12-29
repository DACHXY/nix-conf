{ lib, pkgs, inputs, nix-version, ... }:

{
  imports = [
    ./hardware-configuration.nix
    inputs.home-manager.nixosModules.default

    # Modules
    ./boot.nix
    ../../modules/dn-ca.nix
    ../../modules/fonts.nix
    ../../modules/hardware.nix
    ../../modules/hyprland.nix
    ../../modules/internationalisation.nix
    ../../modules/misc.nix
    ../../modules/networking.nix
    ../../modules/nixsettings.nix
    ../../modules/packages.nix
    ../../modules/plymouth.nix
    ../../modules/polkit.nix
    ../../modules/programs.nix
    ../../modules/security.nix
    ../../modules/services.nix
    ../../modules/sound.nix
    ../../modules/theme.nix
    ../../modules/time.nix
    ../../modules/users.nix
    ../../modules/virtualization.nix
    ../../modules/wireguard.nix
  ];

  # Overrides
  networking.hostName = lib.mkForce "dn-lap";
  programs.steam.enable = lib.mkForce false;

  system.stateVersion = nix-version;
  home-manager = {
    backupFileExtension = "backup";
    extraSpecialArgs = { inherit inputs system nix-version; };
    users = { "danny" = import ../../../home; };
  };
}

