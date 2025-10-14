{ config, ... }:
let
  inherit (config.systemConf) username;
in
{
  mail-server =
    let
      domain = "net.dn";
    in
    {
      inherit domain;

      enable = true;
      openFirewall = true;
      configureNginx = true;
      hostname = "mx1";
      extraDomains = [
        "mail.${domain}"
      ];
      caFile = "" + ../../../extra/ca.crt;
      rootAlias = "${username}";
      networks = [
        "127.0.0.0/8"
        "10.0.0.0/24"
      ];
      virtual = ''
        admin@${domain} ${username}@${domain}
        postmaster@${domain} ${username}@${domain}
      '';
      webmail = {
        enable = true;
        hostname = "mail.${domain}";
      };
      keycloak = {
        dbSecretFile = config.sops.secrets."oauth/password".path;
        adminAccountFile = config.sops.secrets."oauth/adminEnv".path;
      };
      ldap = {
        filter = "(&(objectClass=inetOrgPerson)(objectClass=mailRoutingObject)(uid=%{user | username}))";
        extraAuthConf = ''
          auth_username_format = %{user | lower}
          fields {
            user = %{ldap:mail}
            password = %{ldap:userPassword}
          }
        '';
        secretFile = config.sops.secrets."ldap/password".path;
        webSecretFile = config.sops.secrets."ldap/env".path;
      };
      rspamd = {
        secretFile = config.sops.secrets."rspamd".path;
        trainerSecretFile = config.sops.secrets."rspamd-trainer".path;
      };
      dovecot.oauth = {
        enable = true;
      };
    };
}
