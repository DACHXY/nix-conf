{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkForce;
  inherit (config.systemConf) username;
in
{
  systemConf.security.allowedDomains = [
    "registry-1.docker.io"
    "auth.docker.io"
    "login.docker.com"
    "auth.docker.com"
    "production.cloudflare.docker.com"
    "docker-images-prod.6aa30f8b08e16409b46e0173d6de2f56.r2.cloudflarestorage"
    "api.docker.com"
    "cdn.segment.com"
    "api.segment.io"
  ];

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
        hostname = "mail.dnywe.com";
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

  virtualisation.oci-containers.containers.phpLDAPadmin = {
    environment = {
      LDAP_ALLOW_GUEST = "true";
      LOG_LEVEL = "debug";
      LDAP_LOGGING = "true";
    };
  };

  services.openldap.settings = {
    attrs.olcLogLevel = mkForce "config";
    # children."cn=schema".includes = extraSchemas;
  };
}
