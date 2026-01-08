{ config, ... }:
{
  imports = [
    ./actual-budget.nix
    ./bitwarden.nix
    ./minecraft-server.nix
    ./mail-server.nix
    ./nextcloud.nix
    ./paperless-ngx.nix
    ./metrics.nix
    ./forgejo.nix
    ./keycloak.nix
    ./netbird.nix
    ./hideTTY.nix
    # (import ../../../modules/opencloud.nix {
    #   fqdn = "opencloud.net.dn";
    #   envFile = config.sops.secrets."opencloud".path;
    # })
    (import ./ntfy.nix { fqdn = "ntfy.net.dn"; })
  ];
}
