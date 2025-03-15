{ ... }:
{
  imports = [
    ./plymouth.nix # Boot splash
    ./fonts.nix
    ./hardware.nix
    ./hyprland.nix
    ./internationalisation.nix
    ./misc.nix
    ./nixsettings.nix
    ./programs.nix
    ./security.nix
    ./sound.nix
    ./time.nix
    ./theme.nix
    ./users.nix
    ./environment.nix
    ./virtualization.nix
    ./gc.nix
    ./polkit.nix
    ./lsp.nix
    ./tmux.nix
  ];
}
