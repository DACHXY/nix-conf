{
  fqdn ? null,
  proxy ? true,
}:
{
  config,
  lib,
  ...
}:
let
  inherit (builtins) toString;
  inherit (lib) mkIf;

  finalFqdn = if fqdn != null then fqdn else config.networking.fqdn;
in
{
  services = {
    actual = {
      enable = true;
      settings = {
        port = 31000;
        hostname = "127.0.0.1";
        serverFiles = "/var/lib/actual/server-files";
        userFiles = "/var/lib/actual/user-files";
        loginMethod = "openid";
      };
    };

    actual-budget-api = {
      enable = true;
      listenPort = 31001;
      listenHost = "127.0.0.1";
      serverURL = "https://${finalFqdn}";
    };
  };

  services.nginx.virtualHosts."${finalFqdn}" = mkIf proxy {
    enableACME = true;
    forceSSL = true;

    locations."/api/".proxyPass =
      "http://127.0.0.1:${toString config.services.actual-budget-api.listenPort}/";
    locations."/".proxyPass = "http://127.0.0.1:${toString config.services.actual.settings.port}";
  };
}
