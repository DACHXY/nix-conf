{ config, ... }:
{
  imports = [
    ./actual-budget.nix
    ./bitwarden.nix
    # ./docmost.nix
    ./mail-server.nix
    ./nextcloud.nix
    ./paperless-ngx.nix
    ./metrics.nix
    # (import ../../../modules/opencloud.nix {
    #   fqdn = "opencloud.net.dn";
    #   envFile = config.sops.secrets."opencloud".path;
    # })
    (import ./ntfy.nix { fqdn = "ntfy.net.dn"; })
  ];
}
