{ config, pkgs, ... }:

{
  users.users.danny = {
    isNormalUser = true;
    shell = pkgs.bash; # Actually fish 
    extraGroups = [ "wheel" "input" "networkmanager" "docker" ];
  };
}
