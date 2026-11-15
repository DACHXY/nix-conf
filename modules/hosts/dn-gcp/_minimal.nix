{ lib, pkgs, ... }:
{
  # dn-gcp is a 2 vCPU / 969 MiB GCE guest: no GPU, no display, no local
  # hardware. The shared `nixos.base` profile carries a full desktop stack
  # (mesa + 32-bit drivers, linux-firmware, gtk cursor/icon themes via
  # home-manager, ffmpeg/mpv/imagemagick, devenv) worth ~4 GiB of store on a
  # box that never opens a window. Force it off here instead of touching
  # every other host.
  hardware.graphics.enable = lib.mkForce false;
  hardware.graphics.enable32Bit = lib.mkForce false;
  hardware.enableRedistributableFirmware = lib.mkForce false;
  hardware.enableAllFirmware = lib.mkForce false;
  hardware.cpu.intel.updateMicrocode = lib.mkForce false;

  # No dotfile deployment: a login, an SSH key and fish are the whole user
  # environment.
  home-manager.users = lib.mkForce { };

  # The base profile ships a NetworkManager desktop stack (NM + nm-applet +
  # the openconnect plugin, which drags in webkitgtk). A GCE guest uses
  # systemd-networkd + DHCP instead (see networking.nix).
  networking.networkmanager.enable = lib.mkForce false;
  networking.networkmanager.plugins = lib.mkForce [ ];
  programs.nm-applet.enable = lib.mkForce false;

  # No display, no fonts to render them with.
  fonts.packages = lib.mkForce [ ];
  fonts.fontconfig.enable = lib.mkForce false;

  programs.command-not-found.enable = lib.mkForce false;
  # Bluetooth / geolocation are inherited from nixos.base (blueman is a GTK
  # app) and are pointless on a cloud VM.
  hardware.bluetooth.enable = lib.mkForce false;
  services.blueman.enable = lib.mkForce false;
  services.geoclue2.enable = lib.mkForce false;

  # Pin the shells to absolute store paths so a future package-list change
  # cannot lock us out again.
  users.users.root.shell = lib.mkForce "${pkgs.bashInteractive}/bin/bash";
  users.users.danny.shell = lib.mkForce "${pkgs.fish}/bin/fish";

  # NOTE: `environment.systemPackages` is deliberately NOT forced here.
  # Everything the other modules contribute (coreutils, gnugrep, procps,
  # util-linux, ...) lands in /run/current-system/sw/bin through that option,
  # and forks of the box that lack it cannot even run `ls` in a login shell.
  # The weight we actually saved lives in hardware.graphics / firmware /
  # fonts / home-manager / NetworkManager above.
}
