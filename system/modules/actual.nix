{
  fqdn ? null,
}:
{ config, ... }:
let
  inherit (builtins) toString;
  finalFqdn = if fqdn != null then fqdn else config.networking.fqdn;
in
{
  services.actual = {
    enable = true;
    settings = {
      port = 31000;
      hostname = "127.0.0.1";
      serverFiles = "/var/lib/actual/server-files";
      userFiles = "/var/lib/actual/user-files";
      loginMethod = "openid";
    };
  };

  services.actual-budget-api = {
    enable = true;
    listenPort = 31001;
    listenHost = "127.0.0.1";
    serverURL = "https://${finalFqdn}";
  };

  services.nginx.virtualHosts."${finalFqdn}" = {
    enableACME = true;
    forceSSL = true;

    locations."/api/".proxyPass =
      "http://localhost:${toString config.services.actual-budget-api.listenPort}/";
    locations."/".proxyPass = "http://localhost:${toString config.services.actual.settings.port}";
  };
}
