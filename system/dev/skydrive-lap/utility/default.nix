{ config, ... }:
{
  imports = [
    ../../../modules/printer.nix
    ../../../modules/localsend.nix
    (import ../../../modules/airplay.nix { hostname = config.networking.hostName; })
  ];
}
