{ inputs, ... }:
{
  configurations.nixos.dn-workstation.module = { pkgs, ... }: {
    imports = [ inputs.openlogi.nixosModules.default ];

    programs.openlogi = {
      enable = true;
      package = pkgs.openlogi;
    };
  };
}
