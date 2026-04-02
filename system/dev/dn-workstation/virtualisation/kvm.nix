{ config, pkgs, ... }:
let
  inherit (config.systemConf) username;
in
{
  programs.virt-manager.enable = true;

  users.groups.libvirtd.members = [ username ];

  virtualisation = {
    libvirtd = {
      enable = true;
      qemu.swtpm.enable = true;
      qemu.vhostUserPackages = with pkgs; [ virtiofsd ];
    };
    spiceUSBRedirection.enable = true;
  };

  environment.systemPackages = with pkgs; [
    # dnsmasq
    qemu
    quickemu
  ];
}
