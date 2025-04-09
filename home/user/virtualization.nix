{ ... }:
{
  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = [ "qemu:///system" ];
      uris = [ "qemu:///system" ];
    };
  };

  # default network can be start with:
  # > virsh net-start default
  # or autostart:
  # > virsh net-autostart default
}
