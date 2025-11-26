{
  lib,
  config,
  ...
}:
let
  configDir = ../config;
  browser = "zen.desktop";
in
{
  home.file."${config.home.homeDirectory}/.config/starship.toml".source =
    lib.mkForce "${configDir}/starship/starship.toml";

  home.file = {
    ".config/neofetch".source = "${configDir}/neofetch";
    ".config/rofi".source = "${configDir}/rofi";
    ".config/scripts".source = "${configDir}/scripts";
    ".config/gh" = {
      recursive = true;
      source = "${configDir}/gh";
    };
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
      "x-scheme-handler/http" = browser;
      "x-scheme-handler/https" = browser;
    };
  };
}
