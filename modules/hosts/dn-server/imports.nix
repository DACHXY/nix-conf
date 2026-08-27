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

      boot.kernelParams = [ "split_lock_detect=off" ];
    };
}
