{
  nix-version,
  username,
  lib,
  ...
}:
{
  imports = [
    ./user/bin.nix
    ./user/config.nix
    ./user/direnv.nix
    ./user/environment.nix
    ./user/git.nix
    # ./user/gtk.nix
    # ./user/hyprland.nix
    ./user/nvim.nix
    # ./user/programs.nix
    ./user/shell.nix
    # ./user/swaync.nix
    # ./user/virtualization.nix
  ];

  home = {
    inherit username;
    homeDirectory = "/home/${username}";
    stateVersion = nix-version;
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  programs.vscode.enable = lib.mkForce false;
}
