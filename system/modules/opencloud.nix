{
  fqdn ? null,
  https ? false,
  envFile ? null,
}:
{ config, lib, ... }:
let
  inherit (lib) optionalString mkIf;
  finalFqdn = if fqdn == null then config.networking.fqdn else fqdn;
in
{
  services.opencloud = {
    enable = true;
    url = "http${optionalString https "s"}://${finalFqdn}";
    environmentFile = envFile;
  };

  services.nginx.virtualHosts."${finalFqdn}" = mkIf https {
    enableACME = true;
    forceSSL = true;
    locations."/".proxyPass = "http://127.0.0.1:${toString config.services.opencloud.port}";
  };
}
