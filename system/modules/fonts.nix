{ pkgs, nix-version, ... }:
let
  nerdfont-pkg = if nix-version == "25.05" then pkgs.nerd-fonts.caskaydia-cove else (pkgs.nerdfonts.override { fonts = [ "CascadiaCode" ]; });
in
{
  fonts.packages = (with pkgs; [
    font-awesome
    jetbrains-mono
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-emoji
  ]) ++ ([
    nerdfont-pkg
  ]);

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
