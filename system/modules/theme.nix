{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    adwaita-icon-theme # default gnome cursors
    glib
    gsettings-desktop-schemas
  ];
}
