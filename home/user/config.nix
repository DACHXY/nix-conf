let
  configDir = ../config;
  browser = "zen.desktop";
in
{
  home.file = {
    ".config/neofetch".source = "${configDir}/neofetch";
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
    ".face".source = "${configDir}/.face";
  };

  xdg.mimeApps = {
    enable = true;
    associations.added = {
      "application/pdf" = [ browser ];
      "image/jpeg" = [ browser ];
      "image/png" = [ browser ];
    };
    defaultApplications = {
      "text/html" = browser;
      "application/pdf" = [ browser ];
      "image/jpeg" = [ browser ];
      "image/png" = [ browser ];
    };
  };
}
