{ lib, ... }:
let
  inherit (lib) mkForce;
in
{
  imports = [
    ../environment.nix
    ../hardware.nix
    ../internationalisation.nix
    ../misc.nix
    ../networking.nix
    ../nixsettings.nix
    ../packages.nix
    ../programs.nix
    ../services.nix
    ../sound.nix
    ../time.nix
    ../users.nix
    ../tmux.nix
    ../ca.nix
    ../sops-nix.nix
    ../gc.nix
    ../security.nix
    ../systemd-resolv.nix
  ];

  # Disable man cache
  documentation.man.generateCaches = mkForce false;
}
