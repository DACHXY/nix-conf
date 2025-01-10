{inputs, ...}: {
  imports = [
    ./git.nix
    ./gtk.nix
    ./shell.nix
    ./config.nix
    ./packages.nix
    ./programs.nix
    ./environment.nix
    ./virtualization.nix
    ./hyprland.nix
    ./swaync.nix
    ./desktop.nix
    ./neovim.nix
    inputs.hyprland.homeManagerModules.default
  ];

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;

      permittedInsecurePackages = [
        "electron-25.9.0" # Obsidian
      ];
    };
  };
}
