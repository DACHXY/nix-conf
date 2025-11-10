{
  fqdn ? null,
}:
{ config, ... }:
let
  port = 31004;
  finalFqdn = if fqdn == null then config.networking.fqdn else fqdn;
in
{
  systemConf.security.allowedDomains = [
    "ntfy.sh"
  ];

  services.ntfy-sh = {
    enable = true;
    settings = {
      listen-http = ":${toString port}";
      base-url = "https://${finalFqdn}";
      upstream-base-url = "https://ntfy.sh";
      behind-proxy = true;
      proxy-trusted-hosts = "127.0.0.1";
    };
  };

  services.nginx.virtualHosts = {
    "${finalFqdn}" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyWebsockets = true;
        proxyPass = "http://127.0.0.1:${toString port}";
      };
    };
  };
}
