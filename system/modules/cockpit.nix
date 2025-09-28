{
  enableNginx ? false,
  domain,
}:
{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkIf;
in
{
  services.cockpit = {
    enable = true;
    openFirewall = true;
    allowed-origins = [
    ];
    settings = {
      WebService = {
        ProtocolHeader = "X-Forwarded-Proto";
        ForwardedForHeader = "X-Forwarded-For";
        LoginTo = false;
      };
    };
  };

  services.nginx.virtualHosts."${domain}" = mkIf enableNginx {
    enableACME = true;
    forceSSL = true;
    locations."/".proxyPass = "http://localhost:${toString config.services.cockpit.port}";
  };
}
