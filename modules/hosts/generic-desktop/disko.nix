{ inputs, ... }:
let
  # Target disk for `disko` (nixos-anywhere / disko --mode destroy,format,mount).
  # THIS ERASES THE WHOLE DISK.
  device = "/dev/nvme0n1";
in
{
  configurations.nixos.generic-desktop.module = {
    imports = [ inputs.disko.nixosModules.disko ];

    disko.devices = {
      disk = {
        main = {
          inherit device;
          type = "disk";
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                type = "EF00";
                size = "1G";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [ "umask=0077" ];
                };
              };
              root = {
                size = "100%";
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/";
                };
              };
            };
          };
        };
      };
    };
  };
}
