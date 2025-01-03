{ nix-version, username, ... }:

{
  imports = [ ./user ];
  home.username = username;
  home.homeDirectory = "/home/${username}";

  home.stateVersion = nix-version;

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
