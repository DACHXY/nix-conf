{ config, pkgs, lib, ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.kernelParams =
    [ "nvidia-drm.fbdev=1" "nvidia.NVreg_PreserveVideoMemoryAllocations=1" ];
  boot.extraModprobeConfig = ''
    options hid_apple fnmode=2
    options nvidia_drm modeset=1 dbdev=1
  '';

  boot.initrd.systemd.enable = true;
  boot.initrd.kernelModules =
    [ "nvidia" "i915" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
  boot.swraid.enable = true;
  boot.swraid.mdadmConf =
    "\n  MAILADDR smitty\n  ARRAY /dev/md126 metadata=1.2 name=stuff:0\n  UUID=3b0b7c51-2681-407e-a22a-e965a8aeece7\n  ";
}
