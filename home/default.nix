{ nix-version, ... }:

{
  imports = [ ./user ];
  home.username = "danny";
  home.homeDirectory = "/home/danny";

  home.stateVersion = nix-version;

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
