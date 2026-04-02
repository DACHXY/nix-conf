{
  # Enable F keys in some wireless keyboard (Ex. neo65)
  boot.extraModprobeConfig = ''
    options hid_apple fnmode=2
  '';
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  fileSystems."/mnt/ssd" = {
    device = "/dev/disk/by-label/DN-SSD";
    fsType = "exfat";
    options = [
      "x-systemd.automount"
      "noauto"
      "x-systemd.idle-timeout=600"
      "nofail"
      "user"
      "x-gvfs-show"
      "gid=1000"
      "uid=1000"
      "dmask=000"
      "fmask=000"
      "exec"
    ];
  };
}
