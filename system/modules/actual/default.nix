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
  inherit (lib) mkIf;

  finalFqdn = if fqdn != null then fqdn else config.networking.fqdn;
in
{
  users.users.actual = {
    isSystemUser = true;
    group = "actual";
  };

  users.groups.actual = { };

  services = {
    actual = {
      enable = true;
      user = config.users.users.actual.name;
      group = config.users.users.actual.group;
      settings = {
        port = 31000;
        hostname = "127.0.0.1";
        serverFiles = "/var/lib/actual/server-files";
        userFiles = "/var/lib/actual/user-files";
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
    forceSSL = true;

    locations."/api/".proxyPass =
      "http://127.0.0.1:${toString config.services.actual-budget-api.listenPort}/";
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.services.actual.settings.port}";
      extraConfig = ''
        proxy_hide_header Cross-Origin-Embedder-Policy;
        proxy_hide_header Cross-Origin-Opener-Policy;
        add_header Cross-Origin-Embedder-Policy "require-corp" always;
        add_header Cross-Origin-Opener-Policy "same-origin" always;
        add_header Origin-Agent-Cluster "?1" always;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header Host $host;
      '';
    };
  };
}
