{ config, pkgs, ... }:

{
  users.users.danny = {
    isNormalUser = true;
    shell = pkgs.nushell;
    extraGroups = [ "wheel" "input" "networkmanager" "docker" ];
  };
}
