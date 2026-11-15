# GCE UEFI instances have no persistent EFI variables and boot the
# removable-media fallback path (\EFI\BOOT\BOOTX64.EFI), which systemd-boot
# installs as well — so NVRAM is never written. `nixos.base` sets
# canTouchEfiVariables = true, hence the mkForce.
# console=ttyS0 keeps `gcloud compute connect-to-serial-port` usable as the
# out-of-band recovery channel.
{
  configurations.nixos.dn-gcp.module =
    { lib, ... }:
    {
      boot.loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = lib.mkForce false;
        timeout = 0;
      };

      boot.kernelParams = [
        "console=ttyS0,115200n8"
        "panic=10"
        "boot.panic_on_fail"
      ];
    };
}
