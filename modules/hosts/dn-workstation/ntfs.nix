{
  configurations.nixos.dn-workstation.module = {
    boot.supportedFilesystems = [ "ntfs" ];
    fileSystems."/mnt/windows" = {
      device = "/dev/disk/by-uuid/D24249084248F2B1";
      fsType = "ntfs-3g";
      options = [
        "rw"
        "uid=1000"
        "nofail"
      ];
    };
  };
}
