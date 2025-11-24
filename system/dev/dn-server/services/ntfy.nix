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
    "web.push.apple.com"
  ];

  services.ntfy-sh = {
    enable = true;
    settings = {
      listen-http = ":${toString port}";
      base-url = "https://${finalFqdn}";
      upstream-base-url = "https://ntfy.sh";
      behind-proxy = true;
      proxy-trusted-hosts = "127.0.0.1";
      auth-default-access = "deny-all";
      enable-login = true;
      auth-file = "/var/lib/ntfy-sh/user.db";
      web-push-public-key = "BHN3E5Mwckakf6gOf2uAaiTueB-2L6i96QA1l0r1rSTX_N4qGtMgobmIgEfdY6LAFxradYLtRmwEzTzEnp_Xs5w";
      web-push-file = "/var/lib/ntfy-sh/webpush.db";
    };
    environmentFile = config.sops.secrets."ntfy".path;
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
