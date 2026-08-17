{ inputs, ... }:
{

  flake.modules.nixos.secure-boot =
    { pkgs, lib, ... }:
    {
      imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];

      environment.systemPackages = with pkgs; [
        sbctl
      ];

      boot = {
        loader.systemd-boot.enable = lib.mkForce false;
        lanzaboote = {
          enable = true;
          autoGenerateKeys.enable = true;
          pkiBundle = "/var/lib/sbctl";
        };
      };
    };
}
