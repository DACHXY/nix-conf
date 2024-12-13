{ pkgs, ... }:

{
  fonts.packages = with pkgs; [
    font-awesome
    jetbrains-mono
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif

    (nerdfonts.override { fonts = [ "CascadiaCode" ]; })
  ];

  fonts.fontconfig = {
    defaultFonts = {
      serif = [ "CaskaydiaCove Nerd Font" "Noto Sans CJK" ];
      sansSerif = [ "CaskaydiaCove Nerd Font" "Noto Sans CJK" ];
      monospace = [ "CaskaydiaCove Nerd Font Mono" ];
    };
  };
}
