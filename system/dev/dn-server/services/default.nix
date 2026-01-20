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
    ./dns.nix
    ./acme.nix
    ./ntfy.nix
  ];
}
