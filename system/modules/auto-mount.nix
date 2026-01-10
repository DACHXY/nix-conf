{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # USB auto mount
    usbutils
    udiskie
    udisks
  ];

  services = {
    # USB auto mount
    gvfs.enable = true;
    udisks2.enable = true;
    devmon.enable = true;
  };
}
