{ lib, ... }:
{
  configurations.nixos.dn-server.module =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        steamcmd
        steam-tui
      ];

      programs.steam = {
        enable = true;
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
        extraCompatPackages = with pkgs; [
          proton-ge-bin
        ];
      };

      networking.hosts = {
        "2.19.181.11" = [ "client-download.steampowered.com" ];
        "2.19.181.10" = [ "client-download.steampowered.com" ];
      };
    };

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "steam"
      "steam-unwrapped"
    ];
}
