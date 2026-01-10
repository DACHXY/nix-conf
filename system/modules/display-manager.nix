{ pkgs, config, ... }:
let
  inherit (config.systemConf.sddm) theme package;
in
{
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = theme;
    settings.Theme.Current = theme;
  };

  environment.systemPackages = with pkgs.kdePackages; [
    package
    qtmultimedia
    qtbase
    qtwayland
  ];
}
