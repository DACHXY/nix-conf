{ config, lib, ... }:
let
  inherit (lib) mkForce;
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
        filter = "(&(objectClass=inetOrgPerson)(objectClass=inetMailRoutingObject)(uid=%{user | username}))";
        extraAuthConf = ''
          auth_username_format = %{user | lower}
          fields {
            user = %{ldap:mail}
            password = %{ldap:userPassword}
          }
        '';
        secretFile = config.sops.secrets."ldap/password".path;
        webSecretFile = config.sops.secrets."ldap/env".path;
        olcAccess =
          let
            olcDN = "dc=net,dc=dn";
          in
          [
            ''
              {0}to attrs=userPassword
                  by peername="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth" manage
                  by dn.exact="cn=admin,${olcDN}" manage
                  by dn.exact="uid=admin,ou=people,${olcDN}" manage
                  by self write
                  by anonymous auth
                  by * none
            ''
            ''
              {1}to *
                  by peername="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth" manage
                  by dn.exact="cn=admin,${olcDN}" manage
                  by dn.exact="uid=admin,ou=people,${olcDN}" manage
                  by self read
                  by anonymous auth
                  by * none
            ''
          ];
      };
      rspamd = {
        secretFile = config.sops.secrets."rspamd".path;
        trainerSecretFile = config.sops.secrets."rspamd-trainer".path;
      };
      dovecot.oauth = {
        enable = true;
      };
    };

  services.openldap.settings.attrs.olcLogLevel = mkForce "config";

  services.postfix.settings.main = {
    # internal_mail_filter_classes = [ "bounce" ];
  };

  services.rspamd = {
    locals."logging.conf".text = ''
      level = "debug";
    '';
    locals."settings.conf".text = ''
      bounce {
        id = "bounce";
        priority = high;
        ip = "127.0.0.1";
        selector = 'smtp_from.regexp("/^$/").last';

        apply {
          BOUNCE = -25.0;
        }

        symbols [ "BOUNCE" ]
      }
    '';
  };
}
