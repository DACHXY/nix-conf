{
  config,
  ...
}:
let
  inherit (config.networking) domain;

  gcpIP = "10.10.0.1";
in
{
  services.nginx = {
    enable = true;
    enableReload = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedTlsSettings = true;
    recommendedProxySettings = true;

    virtualHosts."manage.stalwart.${domain}" = {
      useACMEHost = domain;
      forceSSL = true;
      locations."/".proxyPass = "http://${gcpIP}:8081";
    };
  };
}
