{ pkgs, ... }:

let
  addons = with pkgs; [
    fcitx5-gtk
    fcitx5-mozc # Japanese
    fcitx5-chinese-addons
    fcitx5-rime # Bopomofo
    rime-data
  ];
in
{
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" ];

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = addons;
  };

  systemd.user.services.fcitx5 = {
    enable = true;
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    description = "Fcitx5 Input Method";
    environment = {
      GTK_IM_MODULE = "";
      XMODIFIERS = "@im=fcitx";
      QT_IM_MODULE = "fcitx";
    };
    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = 2;
      ExecStart = "/run/current-system/sw/bin/fcitx5";
    };
  };
}
