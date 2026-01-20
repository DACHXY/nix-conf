{ config, ... }:
let
  inherit (config.networking) domain;
  inherit (config.sops) secrets;

  hostname = "actual.${domain}";
  oidcURL = "https://${config.services.keycloak.settings.hostname}/realms/master";
in
{
  sops.secrets."actual/clientSecret" = {
    owner = "actual";
    group = "actual";
    mode = "640";
  };

  imports = [
    (import ../../../modules/actual {
      fqdn = hostname;
    })
  ];

  services.nginx.virtualHosts."${hostname}" = {
    useACMEHost = domain;
  };

  services.actual.settings = {
    loginMethod = "openid";
    allowedLoginMethods = [ "openid" ];
    openId = {
      discoveryURL = "${oidcURL}/.well-known/openid-configuration";
      client_id = "actual";
      client_secret._secret = secrets."actual/clientSecret".path;
      server_hostname = "https://${hostname}";
      authMethod = "openid";
    };
  };
}
