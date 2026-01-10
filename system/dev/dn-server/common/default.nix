{
  imports = [
    ../../../modules/presets/minimal.nix
    ../../../modules/bluetooth.nix
    ../../../modules/gc.nix
    ../../../modules/stylix.nix
    ../../../modules/postgresql.nix
    ./backup.nix
    ./boot.nix
    ./hardware-configuration.nix
    ./networking.nix
    ./nvidia.nix
  ];
}
