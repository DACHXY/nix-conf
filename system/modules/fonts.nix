{
  pkgs,
  lib,
  nix-version,
  ...
}:
let
  nerdfont-pkg =
    if nix-version == "25.05" then
      pkgs.nerd-fonts.caskaydia-cove
    else
      (pkgs.nerdfonts.override { fonts = [ "CascadiaCode" ]; });

  sf-pro-display-bold = pkgs.callPackage ../../pkgs/fonts/sf-pro-display-bold { };
in
{
  fonts.packages =
    (with pkgs; [
      font-awesome
      jetbrains-mono
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-emoji
      sf-pro-display-bold
    ])
    ++ [
      nerdfont-pkg
    ];

  fonts.fontDir.enable = true;

  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      serif = [
        "CaskaydiaCove Nerd Font"
        "Noto Sans CJK"
      ];
      sansSerif = [
        "CaskaydiaCove Nerd Font"
        "Noto Sans CJK"
      ];
      monospace = [ "CaskaydiaCove Nerd Font Mono" ];
    };
    cache32Bit = true;
  };
}
