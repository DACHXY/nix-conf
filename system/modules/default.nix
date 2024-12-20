{ ... }:

{
  imports = [
    ./boot.nix
    ./plymouth.nix # Boot splash 
    ./fonts.nix
    ./gaming.nix
    ./hardware.nix
    ./hyprland.nix
    ./internationalisation.nix
    ./misc.nix
    ./networking.nix
    ./nixsettings.nix
    ./packages.nix
    ./polkit.nix
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
  ];
}
