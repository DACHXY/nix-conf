{
  imports = [
    ../../../modules/postgresql.nix
    ./mail.nix
    ./nginx.nix
    ./wireguard.nix
    # ./netbird.nix
  ];
}
