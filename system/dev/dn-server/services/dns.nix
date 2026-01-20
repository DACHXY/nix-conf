{ config, lib, ... }:
let
  inherit (builtins) listToAttrs;
  inherit (lib) nameValuePair mkForce;
  inherit (config.sops) secrets;
  inherit (config.networking) domain;

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
      allow-dnsupdate-from=10.0.0.0/24
      allow-axfr-ips=10.0.0.0/24
      also-notify=10.0.0.148:53
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
      "10.0.0.0/24"
      "192.168.100.0/24"
    ];
    dns.port = 5300;
    yaml-settings = {
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
    "dns.${domain}" = {
      useACMEHost = domain;
      forceSSL = true;
      locations."/dns-query" = {
        extraConfig = ''
          grpc_pass grpc://127.0.0.1:${toString 8053};
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-Host $host;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
          proxy_set_header X-Forwarded-Protocol $scheme;
          proxy_set_header Range $http_range;
          proxy_set_header If-Range $http_if_range;
        '';
      };
    };
    "powerdns.${domain}" = {
      useACMEHost = domain;
      forceSSL = true;
      locations."/api".proxyPass = "http://127.0.0.1:8081";
      locations."/".proxyPass = "http://127.0.0.1:8000";
    };
  };

  systemd.services.pdns-recursor.before = [ "acme-setup.service" ];
  systemd.services.pdns.before = [ "acme-setup.service" ];
}
