{ config, pkgs, ... }:

{
  users.users.danny = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "qemu" "kvm" "libvirtd" "networkmanager" ];
  };
}
