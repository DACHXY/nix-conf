{ ... }:

{
  imports = [
    ./plymouth.nix # Boot splash
    ./fonts.nix
    ./hardware.nix
    ./hyprland.nix
    ./internationalisation.nix
    ./misc.nix
    ./networking.nix
    ./nixsettings.nix
    ./packages.nix
    ./programs.nix
    ./security.nix
    ./services.nix
    ./sound.nix
    ./time.nix
    ./theme.nix
    ./users.nix
    ./wireguard.nix
    ./dn-ca.nix
    ./environment.nix
    ./virtualization.nix
    ./display-manager.nix
    ./gc.nix
    ./polkit.nix
  ];
}
