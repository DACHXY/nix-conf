{ pkgs, ... }:
{
  home.packages = with pkgs; [
    bitwig-studio
  ];
}
