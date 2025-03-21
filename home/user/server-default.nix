{ inputs, ... }:
{
  imports = [
    ./git.nix
    ./gtk.nix
    ./shell.nix
    ./config.nix
    # ./packages.nix
    ./programs.nix
    ./environment.nix
    ./virtualization.nix
    ./hyprland.nix
    ./swaync.nix
    ./nvim.nix
    ./bin.nix
    ./desktops.nix
    ./direnv.nix
    inputs.hyprland.homeManagerModules.default
  ];

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
    };
  };
}
