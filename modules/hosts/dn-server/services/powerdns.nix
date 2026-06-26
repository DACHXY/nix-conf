{ config, ... }:
let
  globalConfig = config;
  inherit (globalConfig.flake.public.config) domain;
  inherit (globalConfig.flake.public.config.services.powerdns) hostname;
  inherit (globalConfig.flake.public.config.machines) dn-cc gcp;
in
{
  configurations.nixos.dn-server.module =
    { config, lib, ... }:
    let
      inherit (builtins) listToAttrs;
      inherit (lib) nameValuePair mkForce;
      inherit (config.sops) secrets;
      inherit (config.server-rules.default) allowed;

      splitDNS = listToAttrs (
        map (x: nameValuePair x "127.0.0.1:5359") [
          "${domain}."
        ]
      );
    in
    {
      services.resolved.enable = mkForce false;

      sops.secrets = {
        "powerdns-admin/secret" = {
          mode = "0660";
          owner = "powerdnsadmin";
          group = "powerdnsadmin";
        };
        "powerdns-admin/salt" = {
          mode = "0660";
          owner = "powerdnsadmin";
          group = "powerdnsadmin";
        };
        powerdns = {
          mode = "0660";
          owner = "pdns";
          group = "pdns";
        };
      };

      services.postgresql = {
        enable = true;
        authentication = ''
          host  powerdnsadmin powerdnsadmin 127.0.0.1/32    trust
        '';
        ensureUsers = [
          {
            name = "powerdnsadmin";
            ensureDBOwnership = true;
          }
          {
            name = "pdns";
            ensureDBOwnership = true;
          }
        ];
        ensureDatabases = [
          "powerdnsadmin"
          "pdns"
        ];
      };

      services.powerdns = {
        enable = true;
        extraConfig = ''
          launch=gpgsql
          loglevel=6
          webserver-password=$WEB_PASSWORD
          api=yes
          api-key=$WEB_PASSWORD
          gpgsql-host=/var/run/postgresql
          gpgsql-dbname=pdns
          gpgsql-user=pdns
          gpgsql-dnssec=yes
          webserver=yes
          webserver-port=8081
          local-port=5359
          dnsupdate=yes
          primary=yes
          secondary=no
          allow-dnsupdate-from=${dn-cc.range},${gcp.range}
          allow-axfr-ips=${dn-cc.range},${gcp.range}
        '';
        secretFile = secrets.powerdns.path;
      };

      services.pdns-recursor = {
        enable = true;
        forwardZones = {
          "dn." = "127.0.0.1:5359";
        }
        // splitDNS;
        forwardZonesRecurse = {
          # ==== Rspamd DNS ==== #
          "multi.uribl.com." = "168.95.1.1";
          "score.senderscore.com." = "168.95.1.1";
          "list.dnswl.org." = "168.95.1.1";
          "dwl.dnswl.org." = "168.95.1.1";

          # ==== Others ==== #
          "tw." = "168.95.1.1";
          "." = "1.1.1.1";
        };
        dnssecValidation = "off";
        dns.allowFrom = [
          "127.0.0.0/8"
        ]
        ++ allowed.ipv4;
        dns.port = 5300;
        settings = {
          webservice.webserver = true;
          recordcache.max_negative_ttl = 60;
        };
      };

      services.dnsdist = {
        enable = true;
        extraConfig = ''
          newServer("127.0.0.1:${toString config.services.pdns-recursor.dns.port}")
          addDOHLocal("0.0.0.0:8053", nil, nil, "/", { reusePort = true })
          getPool(""):setCache(newPacketCache(65535, {maxTTL=86400, minTTL=0, temporaryFailureTTL=60, staleTTL=60, dontAge=false}))
        '';
      };

      services.powerdns-admin = {
        enable = true;
        secretKeyFile = config.sops.secrets."powerdns-admin/secret".path;
        saltFile = config.sops.secrets."powerdns-admin/salt".path;
        config =
          # python
          ''
            import cachelib
            BIND_ADDRESS = "127.0.0.1"
            PORT = 8081
            SESSION_TYPE = 'cachelib'
            SESSION_CACHELIB = cachelib.simple.SimpleCache()
            SQLALCHEMY_DATABASE_URI = 'postgresql://powerdnsadmin@/powerdnsadmin?host=localhost'
          '';
      };

      services.nginx.virtualHosts = {
        "${hostname}" = {
          useACMEHost = domain;
          forceSSL = true;
          locations."/api".proxyPass = "http://127.0.0.1:8081";
          locations."/".proxyPass = "http://127.0.0.1:8000";
        };
      };

      systemd.services.pdns-recursor.before = [ "acme-setup.service" ];
      systemd.services.pdns.before = [ "acme-setup.service" ];
    };
}
