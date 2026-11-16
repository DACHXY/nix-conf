{ lib, pkgs, ... }:
{
  # dn-gcp is a 2 vCPU / 969 MiB GCE guest: no GPU, display or local hardware,
  # yet `nixos.base` carries ~4 GiB of desktop stack (mesa, firmware, fonts,
  # home-manager, devenv). Force that off here instead of touching other hosts.
  hardware.graphics.enable = lib.mkForce false;
  hardware.graphics.enable32Bit = lib.mkForce false;
  hardware.enableRedistributableFirmware = lib.mkForce false;
  hardware.enableAllFirmware = lib.mkForce false;
  hardware.cpu.intel.updateMicrocode = lib.mkForce false;

  # No dotfile deployment: login, SSH key and fish are the whole environment.
  home-manager.users = lib.mkForce { };

  # The base profile's NetworkManager stack (nm-applet + openconnect pulls in
  # webkitgtk) is replaced by systemd-networkd + DHCP (see networking.nix).
  networking.networkmanager.enable = lib.mkForce false;
  networking.networkmanager.plugins = lib.mkForce [ ];
  programs.nm-applet.enable = lib.mkForce false;

  # No display, no fonts to render them with.
  fonts.packages = lib.mkForce [ ];
  fonts.fontconfig.enable = lib.mkForce false;

  programs.command-not-found.enable = lib.mkForce false;
  # Bluetooth / geolocation come from nixos.base and are pointless on a VM.
  hardware.bluetooth.enable = lib.mkForce false;
  services.blueman.enable = lib.mkForce false;
  services.geoclue2.enable = lib.mkForce false;

  # Absolute store paths, so a package-list change cannot lock us out again.
  users.users.root.shell = lib.mkForce "${pkgs.bashInteractive}/bin/bash";
  users.users.danny.shell = lib.mkForce "${pkgs.fish}/bin/fish";

  # `environment.systemPackages` is deliberately NOT forced: it populates
  # /run/current-system/sw/bin (coreutils, gnugrep, procps, util-linux, ...) and
  # without it a login shell cannot even run `ls`.
}
