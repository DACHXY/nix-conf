{
  flake.modules.nixos.base =
    { lib, pkgs, ... }:
    {
      networking.networkmanager = {
        enable = lib.mkDefault true;
        plugins = with pkgs; [
          networkmanager-fortisslvpn
        ];
      };

      networking = {
        enableIPv6 = lib.mkDefault false;
        firewall.enable = lib.mkDefault true;
      };
    };
}
