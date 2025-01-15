{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    wineWowPackages.waylandFull # 32-bit & 64-bit
    winetricks
  ];
}
