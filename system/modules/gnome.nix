{
  lib,
  ...
}:
{
  environment.sessionVariables = {
    XDG_CURRENT_DESKTOP = "GNOME";
  };

  services.xserver = {
    enable = lib.mkDefault true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };
}
