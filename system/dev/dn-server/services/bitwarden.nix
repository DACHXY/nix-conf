{
  imports = [
    (import ../../../modules/vaultwarden.nix {
      domain = "bitwarden.net.dn";
    })
  ];
}
