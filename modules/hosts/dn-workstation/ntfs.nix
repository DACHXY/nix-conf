{
  configurations.nixos.dn-workstation.module = {
    boot.supportedFilesystems = [ "ntfs" ];
    fileSystems."/mnt/windows" = {
      device = "/dev/nvme2n1p2";
      fsType = "ntfs-3g";
      options = [
        "rw"
        "uid=1000"
      ];
    };
  };
}
