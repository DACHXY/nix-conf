{ ... }:
let configDir = ../config;
in
{
  home.file = {
    ".config/nvim" = {
      source = "${configDir}/nvim";
      recursive = true;
    };
    ".config/wallpapers".source = "${configDir}/wallpapers";
    ".config/kitty".source = "${configDir}/kitty";
    ".config/neofetch".source = "${configDir}/neofetch";
    # ".config/hypr".source = "${configDir}/hypr";
    ".config/swayidle".source = "${configDir}/swayidle";
    ".config/swaylock".source = "${configDir}/swaylock";
    ".config/wlogout".source = "${configDir}/wlogout";
    ".config/waybar" = {
      recursive = true;
      source = "${configDir}/waybar";
    };
    ".config/btop".source = "${configDir}/btop";
    ".config/wofi".source = "${configDir}/wofi";
    ".config/rofi".source = "${configDir}/rofi";
    ".config/mako".source = "${configDir}/mako";
    ".config/scripts".source = "${configDir}/scripts";
    ".config/swaync".source = "${configDir}/swaync";
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
  };
}
