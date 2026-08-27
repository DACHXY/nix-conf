{ config, self, ... }:
let
  inherit (self.lib.ldap) getOlcSuffix;
  inherit (config.flake.public.config) legacy;
  inherit (config.flake.public.config.machines) dn-server;
  inherit (config.flake.public.config.services) mailserver oidc stalwart;
in
{
  configurations.nixos.dn-cc.module =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib) getExe concatMapStringsSep;
      inherit (config.networking) domain;
      inherit (config.services.lldap.settings) ldap_user_dn ldap_base_dn ldap_port;

      package = pkgs.stalwart_0_16;
      managementPort = stalwart.managementPort;
      dbName = "stalwart";
      fqdn = mailserver.hostname;
      oidcIssuerUrl = oidc.issuer;

      # ==== Legacy LDAP ==== #
      legacyDomain = legacy.domain;
      getCredFile = var_name: "/run/credentials/stalwart.service/${var_name}";

      # ==== Datastore-only bootstrap config (replaces stalwart.toml) ==== #
      configJson = pkgs.writeText "stalwart-config.json" (
        builtins.toJSON {
          storage =
            let
              postgresql = {
                "@type" = "PostgreSql";
                host = "127.0.0.1";
                port = 5432;
                database = dbName;
                authUsername = dbName;
                poolMaxConnections = 10;
              };
            in
            {
              data = postgresql;
              blob = postgresql;
              fts = postgresql;
              lookup = {
                "@type" = "Redis";
                url = "redis://127.0.0.1:${toString config.services.redis.servers.stalwart.port}";
              };
            };
        }
      );

      # ==== Declarative server-config plan (replaces directory/store/server
      # settings previously under services.stalwart.settings) ==== #
      plan = [
        {
          "@type" = "update";
          object = "SystemSettings";
          value = {
            defaultHostname = fqdn;
            defaultDomainId = "#dom-main";
          };
        }
        {
          "@type" = "upsert";
          object = "Domain";
          matchOn = [ "name" ];
          value = {
            dom-main = {
              name = domain;
              certificateManagement = {
                "@type" = "Manual";
              };
              dkimManagement = {
                "@type" = "Manual";
              };
              dnsManagement = {
                "@type" = "Manual";
              };
              subAddressing = {
                "@type" = "Disabled";
              };
            };
          };
        }
        {
          "@type" = "update";
          object = "Authentication";
          value = {
            directoryId = "#dir-ldap-legacy";
          };
        }
        {
          "@type" = "upsert";
          object = "Directory";
          matchOn = [ "name" ];
          value = {
            dir-oidc = {
              name = "oidc";
              "@type" = "Oidc";
              issuerUrl = oidcIssuerUrl;
              claimUsername = "preferred_username";
              claimName = "name";
            };
            dir-ldap-legacy = {
              name = "ldap-legacy";
              "@type" = "Ldap";
              url = "ldap://${dn-server.ip}";
              timeout = 10000;
              baseDn = getOlcSuffix legacyDomain;
              bindDn = "cn=admin,${getOlcSuffix legacyDomain}";
              bindSecret = {
                "@type" = "File";
                filePath = getCredFile "ldap_admin_password";
              };
              filterLogin = "(|(uid=?)(mail=?)(mailRoutingAddress=?))";
              filterMailbox = "(|(mail=?)(mailRoutingAddress=?))";
              attrEmail.mail = true;
              attrSecret.userPassword = true;
            };
            dir-lldap = {
              name = "lldap";
              "@type" = "Ldap";
              url = "ldap://127.0.0.1:${toString ldap_port}";
              timeout = 10000;
              baseDn = getOlcSuffix domain;
              bindDn = "cn=${ldap_user_dn},${ldap_base_dn}";
              bindSecret = {
                "@type" = "File";
                filePath = getCredFile "ldap_admin_password";
              };
              filterLogin = "(uid=?)";
              filterMailbox = "(|(mail=?)(mailAlias=?))";
              attrEmail.mail = true;
              attrEmailAlias.mailAlias = true;
              attrSecret.userPassword = true;
            };
          };
        }
        {
          "@type" = "upsert";
          object = "NetworkListener";
          matchOn = [ "name" ];
          value = {
            smtp = {
              name = "smtp";
              protocol = "smtp";
              bind = [ "0.0.0.0:25" ];
            };
            submission = {
              name = "submission";
              protocol = "smtp";
              bind = [ "0.0.0.0:587" ];
              maxConnections = 1024;
            };
            submissions = {
              name = "submissions";
              protocol = "smtp";
              bind = [ "0.0.0.0:465" ];
              tlsImplicit = true;
              maxConnections = 1024;
            };
            imaptls = {
              name = "imaptls";
              protocol = "imap";
              bind = [ "0.0.0.0:993" ];
              tlsImplicit = true;
              maxConnections = 1024;
            };
            management = {
              name = "management";
              protocol = "http";
              bind = [ "127.0.0.1:${toString managementPort}" ];
              useTls = false;
            };
            managesieve = {
              name = "managesieve";
              protocol = "manageSieve";
              bind = [ "0.0.0.0:4190" ];
              maxConnections = 1024;
            };
          };
        }
      ];

      planText = concatMapStringsSep "\n" (op: builtins.toJSON op) plan;
      planFile = pkgs.writeText "stalwart-plan.ndjson" planText;
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
        owner = "stalwart";
        group = "stalwart";
        mode = "640";
      };

      # STALWART_USER/STALWART_PASSWORD for stalwart-bootstrap.service.
      # The matching account must already exist server-side (see file
      # header, step 2) - this template only lets the oneshot authenticate
      # against it on every rebuild.
      sops.templates."stalwart-bootstrap.env" = {
        owner = "stalwart";
        content = ''
          STALWART_USER=admin
          STALWART_PASSWORD=${config.sops.placeholder."stalwart/adminPassword"}
        '';
      };

      users.groups.stalwart = { };
      users.users.stalwart = {
        isSystemUser = true;
        group = "stalwart";
        extraGroups = [ "acme" ];
      };

      networking.firewall.allowedTCPPorts = [
        25
        587
        465
        993
        4190
      ];

      systemd.services.stalwart = {
        description = "Stalwart Mail Server";
        wantedBy = [ "multi-user.target" ];
        after = [
          "network-online.target"
          "postgresql.service"
        ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          Type = "simple";
          User = "stalwart";
          Group = "stalwart";
          Restart = "on-failure";
          RestartSec = 5;
          StateDirectory = "stalwart";
          CacheDirectory = "stalwart";
          LoadCredential = [
            "ldap_admin_password:${config.sops.secrets."lldap/adminPassword".path}"
          ];
          ExecStart = "${getExe package} --config=${configJson}";
          AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
          CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
        };
      };

      systemd.services.stalwart-bootstrap = {
        description = "Stalwart configuration bootstrap";
        after = [ "stalwart.service" ];
        requires = [ "stalwart.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          EnvironmentFile = config.sops.templates."stalwart-bootstrap.env".path;
          Environment = "STALWART_URL=http://127.0.0.1:${toString managementPort}";
          ExecStart = "${getExe pkgs.stalwart-cli} apply --file ${planFile}";
        };
      };

      # Nginx managed by nginx.nix
    };
}
