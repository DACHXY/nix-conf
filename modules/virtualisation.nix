{
  flake.modules.nixos.virtualisation =
    { config, pkgs, ... }:
    let
      username = config.my.user.name;
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
    };
}
