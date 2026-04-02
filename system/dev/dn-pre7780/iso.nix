{
  pkgs,
  lib,
  modulesPath,
  ...
}:
let
in
{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
    # Provide an initial copy of the NixOS channel so that the user
    # doesn't need to run "nix-channel --update" first.
    (modulesPath + "/installer/cd-dvd/channel.nix")
  ];

  hardware.enableRedistributableFirmware = lib.mkDefault true;

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "usb-storage"
    "sd_mod"
    "rtsx_pci_sdmmc"
  ];

  services.fstrim.enable = lib.mkDefault true;

  boot = {
    kernelModules = [
      "kvm-intel"
    ];
    blacklistedKernelModules = [ "nouveau" ];
  };
  boot.kernelParams = [ "i915.modeset=1" ];

  environment.systemPackages = [
    pkgs.neovim
    pkgs.jq
    pkgs.fish
  ];

  networking.networkmanager.enable = true;
  # boot.swraid.enable = true;

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJFQA42R3fZmjb9QnUgzzOTIXQBC+D2ravE/ZLvdjoOQ danny@lap.dn"
  ];
}
