{ pkgs, ... }:

{
  fonts.packages = with pkgs; [
    font-awesome
    jetbrains-mono
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-emoji

    (nerdfonts.override { fonts = [ "CascadiaCode" ]; })
  ];

  fonts.fontDir.enable = true;

  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      serif = [ "CaskaydiaCove Nerd Font" "Noto Sans CJK" ];
      sansSerif = [ "CaskaydiaCove Nerd Font" "Noto Sans CJK" ];
      monospace = [ "CaskaydiaCove Nerd Font Mono" ];
    };
    cache32Bit = true;
  };
}
