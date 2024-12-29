{ config, pkgs, pkgsUnstable, ... }:

{
  imports = [ ./user ];
  home.username = "danny";
  home.homeDirectory = "/home/danny";

  home.stateVersion = "24.11";
  # home.stateVersion = "25.05";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
