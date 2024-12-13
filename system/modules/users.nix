{ config, pkgs, ... }:

{
  users.users.danny = {
    isNormalUser = true;
    shell = pkgs.nushell;
    extraGroups = [ "wheel" "qemu" "kvm" "libvirtd" "networkmanager" ];
  };
}
