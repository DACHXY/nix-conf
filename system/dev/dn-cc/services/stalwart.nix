{
  self,
  helper,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkForce;
  inherit (config.networking) domain;
  inherit (helper.ldap) getOlcSuffix;
  inherit (config.services.lldap.settings) ldap_user_dn ldap_base_dn ldap_port;

  cfg = config.services.stalwart;
  managementPort = 30092;
  realm = "master";
  oidcUserInfoUrl = "https://${self.nixosConfigurations.dn-server.config.services.keycloak.settings.hostname}/realms/${realm}/protocol/openid-connect/userinfo";
  dbName = "stalwart";
  hostname = "mx2";
  fqdn = "${hostname}.${domain}";

  # ==== Legacy LDAP ==== #
  dn-server-ip = "10.20.0.2";
  legacyDomain = "net.dn";

  getFile = filepath: "%{file:${filepath}}%";
  getCredFile = var_name: "%{file:/run/credentials/stalwart.service/${var_name}}%";
in
{
  services.redis.servers.stalwart = {
    enable = true;
    port = 34007;
  };

  services.postgresql = {
    ensureUsers = [
      {
        name = dbName;
        ensureDBOwnership = true;
      }
    ];
    ensureDatabases = [ dbName ];
  };

  sops.secrets."stalwart/adminPassword" = {
    owner = cfg.user;
    group = cfg.group;
    mode = "640";
  };

  users.users.${cfg.user}.extraGroups = [ "acme" ];

  # block outbound for security
  networking.firewall.extraCommands = ''
    iptables -I OUTPUT 1 -p tcp -m multiport --dports 25,465,587,2525 -j REJECT
  '';

  services.stalwart = {
    enable = true;
    openFirewall = true;
    stateVersion = "25.11";
    credentials = {
      ldap_admin_password = config.sops.secrets."lldap/adminPassword".path;
    };

    settings = {
      config.local-keys = [
        "webadmin.resource"
        "store.*"
        "directory.*"
        "tracer.*"
        "!server.blocked-ip.*"
        "!server.allowed-ip.*"
        "!server.auto-ban.*"
        "server.*"
        "authentication.fallback-admin.*"
        "cluster.*"
        "config.local-keys.*"
        "storage.data"
        "storage.blob"
        "storage.lookup"
        "storage.fts"
        "storage.directory"
        "certificate.*"
      ];

      server.hostname = fqdn;

      # ==== Listener ==== #
      server.listener = mkForce {
        smtp = {
          bind = [ "0.0.0.0:25" ];
          protocol = "smtp";
        };
        submission = {
          bind = [ "0.0.0.0:587" ];
          protocol = "smtp";
          max-connections = 1024;
        };
        submissions = {
          bind = [ "0.0.0.0:465" ];
          protocol = "smtp";
          tls.implicit = true;
          max-connections = 1024;
        };
        imaptls = {
          bind = [ "0.0.0.0:993" ];
          protocol = "imap";
          tls.implicit = true;
          max-connections = 1024;
        };
        management = {
          bind = [ "127.0.0.1:${toString managementPort}" ];
          protocol = "http";
        };
      };

      # ==== Directory ==== #
      directory = {
        oidc = {
          type = "oidc";
          timeout = "2s";
          endpoint = {
            method = "userinfo";
            url = oidcUserInfoUrl;
          };
          fields = {
            email = "email";
            username = "preferred_username";
            full-name = "name";
          };
        };
        ldap-legacy = {
          type = "ldap";
          timeout = "10s";
          url = "ldap://${dn-server-ip}";
          base-dn = getOlcSuffix legacyDomain;
          bind = {
            auth.method = "default";
            dn = "cn=admin,${getOlcSuffix legacyDomain}";
            secret = getCredFile "ldap_admin_password";
          };
          filter = {
            name = "(|(uid=?)(mail=?))";
            email = "(|(mail=?)(mailRoutingAddress=?))";
          };
          attributes = {
            name = "uid";
            email = "mail";
            secret = "userPassword";
          };
        };
        lldap = {
          type = "ldap";
          timeout = "10s";
          url = "ldap://127.0.0.1:${toString ldap_port}";
          base-dn = getOlcSuffix domain;
          bind = {
            auth.method = "default";
            dn = "cn=${ldap_user_dn},${ldap_base_dn}";
            secret = getCredFile "ldap_admin_password";
          };
          filter = {
            name = "(uid=?)";
            email = "(|(mail=?)(mailAlias=?))";
          };
          attributes = {
            name = "uid";
            email = "mail";
            secret = "userPassword";
            secret-changed = "pwdChangedTime";
          };
        };
      };

      # ==== Store ==== #
      store = {
        postgresql = {
          type = "postgresql";
          host = "127.0.0.1";
          port = 5432;
          database = dbName;
          user = dbName;
          pool.max-connections = 10;
        };
        redis = {
          type = "redis";
          redis-type = "single";
          urls = "redis://127.0.0.1:${toString config.services.redis.servers.stalwart.port}";
          timeout = "10s";
        };
      };

      # ==== Storage ==== #
      storage = {
        data = "postgresql";
        blob = "postgresql";
        lookup = "redis";
        fts = "postgresql";
        directory = "ldap-legacy";
      };

      # ==== TLS Certificate ==== #
      certificate."default" =
        let
          certDir = config.security.acme.certs."${domain}".directory;
        in
        {
          cert = getFile "${certDir}/fullchain.pem";
          private-key = getFile "${certDir}/key.pem";
          default = true;
        };

      authentication.fallback-admin = {
        user = "admin";
        secret = getFile config.sops.secrets."stalwart/adminPassword".path;
      };
    };
  };

  services.nginx.virtualHosts."stalwart.${domain}" = {
    forceSSL = true;
    useACMEHost = domain;

    locations."/".proxyPass = "http://127.0.0.1:${toString managementPort}";
  };
}
