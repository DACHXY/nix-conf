{ helper, config, ... }:
let
  inherit (config.networking) domain;
  inherit (helper.ldap) getOlcSuffix;
  adminUser = "admin";
  hostname = "ldap";
  fqdn = "${hostname}.${domain}";

  cfg = config.services.lldap;
in
{
  sops.secrets = {
    "lldap/adminPassword" = {
      owner = "lldap";
      group = "lldap";
      mode = "640";
    };
    "lldap/jwtSecret" = {
      owner = "lldap";
      group = "lldap";
      mode = "640";
    };
  };

  users.users.lldap = {
    isSystemUser = true;
    group = "lldap";
  };

  users.groups.lldap = { };

  services.lldap = {
    enable = true;
    settings = {
      ldap_user_email = "${adminUser}@${domain}";
      ldap_user_pass_file = config.sops.secrets."lldap/adminPassword".path;
      ldap_user_dn = adminUser;
      ldap_base_dn = getOlcSuffix domain;
      ldap_host = "0.0.0.0";
      http_host = "127.0.0.1";
      http_url = "https://${fqdn}";
      jwt_secret_file = config.sops.secrets."lldap/jwtSecret".path;
      force_ldap_user_pass_reset = "always";
    };

    database.type = "postgresql";
  };

  services.nginx.virtualHosts."${fqdn}" = {
    forceSSL = true;
    useACMEHost = domain;

    locations."/".proxyPass = "http://127.0.0.1:${toString cfg.settings.http_port}/";
  };
}
