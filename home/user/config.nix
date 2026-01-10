{
  lib,
  config,
  ...
}:
let
  configDir = ../config;
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

  xdg.mimeApps.enable = true;
}
