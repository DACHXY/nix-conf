{ config, ... }:
{
  configurations.nixos.dn-server.module =
    { ... }:
    {
      imports = with config.flake.modules; [
        nixos.server
        nixos.danny
        nixos.danny-acme
        nixos.nvf
        generic.dnywe
      ];
    };
}
