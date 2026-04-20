{ pkgs, ... }:
{
  imports = [
    (import ../../../modules/airplay.nix { })
    (import ../../../modules/localsend.nix { })
  ];

  environment.systemPackages = with pkgs; [ moonlight ];
}
