let configDir = ../config;
in {
  home.file = {
    ".config/nvim" = {
      source = "${configDir}/nvim";
      recursive = true;
    };
    ".config/wallpapers".source = "${configDir}/wallpapers";
    ".config/kitty".source = "${configDir}/kitty";
    ".config/neofetch".source = "${configDir}/neofetch";
    ".config/hypr".source = "${configDir}/hypr";
    ".config/swayidle".source = "${configDir}/swayidle";
    ".config/swaylock".source = "${configDir}/swaylock";
    ".config/wlogout".source = "${configDir}/wlogout";
    ".config/waybar" = {
      recursive = true;
      source = "${configDir}/waybar";
    };
    ".config/btop".source = "${configDir}/btop";
    ".config/wofi".source = "${configDir}/wofi";
    ".config/mako".source = "${configDir}/mako";
    ".config/scripts".source = "${configDir}/scripts";
    ".config/swaync".source = "${configDir}/swaync";
    # ".config/uwsm".source = "${configDir}/uwsm";
    ".config/starship.toml".source = "${configDir}/starship/starship.toml";
    ".config/macchiato.toml".source = "${configDir}/starship/macchiato.toml";
    ".config/gh" = {
      recursive = true;
      source = "${configDir}/gh";
    };
  };
}
