let
  configDir = ../config;
  browser = "firefox-nightly.desktop";
in
{
  home.file = {
    ".config/wallpapers".source = "${configDir}/wallpapers";
    ".config/kitty".source = "${configDir}/kitty";
    ".config/neofetch".source = "${configDir}/neofetch";
    ".config/wlogout".source = "${configDir}/wlogout";
    ".config/waybar" = {
      source = "${configDir}/waybar";
    };
    ".config/btop".source = "${configDir}/btop";
    ".config/rofi".source = "${configDir}/rofi";
    ".config/scripts".source = "${configDir}/scripts";
    ".config/starship.toml".source = "${configDir}/starship/starship.toml";
    ".config/macchiato.toml".source = "${configDir}/starship/macchiato.toml";
    ".config/gh" = {
      recursive = true;
      source = "${configDir}/gh";
    };
    ".local/share/fcitx5/themes/fcitx5-dark-transparent" = {
      recursive = true;
      source = "${configDir}/fcitx5-dark-transparent";
    };
    ".config/fcitx5/conf" = {
      recursive = true;
      source = "${configDir}/fcitx5";
    };
    ".config/electron-flags.conf".source = "${configDir}/electron/electron-flags.conf";
    ".config/ghostty" = {
      recursive = true;
      source = "${configDir}/ghostty";
    };
    ".face".source = "${configDir}/.face";
    ".config/yazi" = {
      recursive = true;
      source = "${configDir}/yazi";
    };
  };

  xdg.mimeApps = {
    enable = true;
    associations.added = {
      "application/pdf" = [ browser ];
    };
    defaultApplications = {
      "text/html" = browser;
      "application/pdf" = [ browser ];
    };
  };
}
