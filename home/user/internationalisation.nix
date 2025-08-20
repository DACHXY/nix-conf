{
  pkgs,
  config,
  lib,
  ...
}:
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
  i18n = {
    inputMethod = {
      enable = true;
      type = "fcitx5";
      fcitx5 = {
        inherit addons;
        waylandFrontend = true;

        settings = {
          addons.classicui.globalSection =
            let
              font = "Noto Sans CJK TC ${toString config.stylix.fonts.sizes.popups}";
            in
            {
              Font = lib.mkForce font;
              MenuFont = lib.mkForce font;
              TrayFont = lib.mkForce font;
            };
        };
      };
    };
  };

  systemd.user.services.fcitx5 = {
    Unit = {
      WantedBy = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
      Description = "Fcitx5 Input Method";
    };
    Service = {
      Type = "simple";
      Restart = "always";
      RestartSec = 2;
      ExecStart = "${pkgs.fcitx5}/bin/fcitx5";
      Environment = [
        "GTK_IM_MODULE="
        "XMODIFIERS=@im=fcitx"
        "QT_IM_MODULE=fcitx"
      ];
    };
  };
}
