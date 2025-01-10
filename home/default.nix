{
  nix-version,
  username,
  ...
}: {
  imports = [./user];
  home = {
    inherit username;
    homeDirectory = "/home/${username}";
    stateVersion = nix-version;
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
