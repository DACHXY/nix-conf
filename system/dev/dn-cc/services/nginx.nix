{
  self,
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (builtins) fetchurl;
  inherit (lib)
    concatStringsSep
    mkForce
    mkAfter
    optionalString
    mkBefore
    ;

  serverRules = config.server-rules;
  serverCfg = self.nixosConfigurations.dn-server.config;
  inherit (serverCfg.networking) domain;
  matrixDomain = "matrix.${domain}";
  matrixAuthDomain = "matrix-auth.${domain}";
  dn-server-ip = "10.20.0.2";

  # ==== Utils ==== #
  mkAllowedList = allowedList: concatStringsSep "\n" (map (v: "allow ${v};") allowedList);

  # ==== Cloudflare ==== #
  cloudflareCert = fetchurl {
    url = "https://developers.cloudflare.com/ssl/static/authenticated_origin_pull_ca.pem";
    sha256 = "sha256:0hxqszqfzsbmgksfm6k0gp0hsx9k1gqx24gakxqv0391wl6fsky1";
  };

  # ==== Cloudflare Proxy ==== #
  realIpsFromList = lib.strings.concatMapStringsSep "\n" (x: "set_real_ip_from  ${x};");
  fileToList = x: lib.strings.splitString "\n" (builtins.readFile x);
  cfipv4 = fileToList (
    pkgs.fetchurl {
      url = "https://www.cloudflare.com/ips-v4";
      sha256 = "0ywy9sg7spafi3gm9q5wb59lbiq0swvf0q3iazl0maq1pj1nsb7h";
    }
  );
  cfipv6 = fileToList (
    pkgs.fetchurl {
      url = "https://www.cloudflare.com/ips-v6";
      sha256 = "1ad09hijignj6zlqvdjxv7rjj8567z357zfavv201b9vx3ikk7cy";
    }
  );

  # ==== Allowed List ==== #
  allowedCountries = serverRules.rule.default.allowed.countryCode;
  allowedIPv4 = serverRules.rule.default.allowed.ipv4;

  # ==== geoip ==== #
  geoDBCountry = fetchurl {
    url = "https://nextcloud.dnywe.com/s/geodb/download";
    sha256 = "sha256:0ir3bmni7756zfma8xfr1bnbszsizaas4gs3sq4zd4qgjl3rhm66";
  };
  geoIpConfig = ''
    set $allow_access 0;
    if ($allowed_country = 1) {
      set $allow_access 1;
    }

    if ($remote_addr ~ ^192\.168\.100\.) {
      set $allow_access 1;
    }

    if ($remote_addr ~ ^127\.) {
      set $allow_access 1;
    }

    if ($remote_addr ~ ^10\.) {
      set $allow_access 1;
    }

    if ($allow_access = 0) {
      return 403;
    }
  '';

  # ==== Proxy Config ==== #
  locationProxyPass = {
    proxyWebsockets = true;
    proxyPass = "https://${dn-server-ip}";
    extraConfig = ''
      proxy_ssl_server_name on;
      limit_req zone=raw_limit burst=150 nodelay;
      limit_req_status 429;
    '';
  };

  mkProxyConfig =
    {
      limitGeo ? true,
    }:
    {
      forceSSL = true;
      useACMEHost = domain;

      extraConfig = lib.mkAfter ''
        if ($http_user_agent ~* "GPTBot") {
          return 444;
        }

        if ($http_user_agent ~* "bot") {
          return 444;
        }

        ssl_client_certificate ${cloudflareCert};
        ssl_verify_client on;

        ${optionalString limitGeo geoIpConfig}
      '';
    };
in

{
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  users.users.nginx.extraGroups = [ "acme" ];

  services.nginx = {
    enable = true;
    package = (pkgs.nginx.override { modules = with pkgs.nginxModules; [ geoip2 ]; });

    appendHttpConfig = ''
      geoip2 ${geoDBCountry} {
        auto_reload 5m;
        $geoip2_country_code country iso_code;
        $geoip2_country_name country names en;
      }

      map $geoip2_country_code $allowed_country {
        default 0;
        ${concatStringsSep "\n  " (map (c: "${c} 1;") allowedCountries)}
      }
    '';

    commonHttpConfig = ''
      log_format main '$remote_addr - $remote_user [$time_local] '
                          '"$host" "$request" "$geoip2_country_code" "$geoip2_country_name" $status $body_bytes_sent '
                          'upstream_status=$upstream_status '
                          'upstream_addr=$upstream_addr '
                          '"$http_referer" "$http_user_agent"';

      access_log /var/log/nginx/access.log main;

      # Cloudflare Proxy
      ${realIpsFromList cfipv4}
      ${realIpsFromList cfipv6}
      real_ip_header CF-Connecting-IP;
      real_ip_recursive on;

      limit_req_zone $binary_remote_addr zone=raw_limit:10m rate=100r/s;
    '';

    defaultListen = mkForce [
      { addr = "0.0.0.0"; }
    ];

    enableReload = true;
    clientMaxBodySize = "40M";
    mapHashMaxSize = 4096;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedTlsSettings = true;
    recommendedProxySettings = true;

    virtualHosts = {
      # ==== Main Domain ==== #
      "${domain}" = {
        useACMEHost = domain;
        forceSSL = true;

        locations."/".extraConfig = ''
          return 404;
        '';

        # Matrix server
        locations."= /.well-known/matrix/server" = locationProxyPass;
        locations."= /.well-known/matrix/client" = locationProxyPass;
      };

      # Default
      "default-ssl" = {
        default = true;
        forceSSL = true;
        useACMEHost = domain;

        extraConfig = ''
          ${geoIpConfig}
        '';

        locations."/" = {
          return = "444";
        };
      };

      "nextcloud.${domain}" = (mkProxyConfig { }) // {
        locations."/" = locationProxyPass;
        locations."^~ /s/geodb" = locationProxyPass // {
          extraConfig = mkBefore ''
            ${mkAllowedList allowedIPv4}
            deny all;
          '';
        };
      };
      "login.${domain}" = (mkProxyConfig { }) // {
        locations."/" = locationProxyPass;
        locations."^~ /admin" = locationProxyPass // {
          extraConfig = mkBefore ''
            ${mkAllowedList allowedIPv4}
            deny all;
          '';
        };
      };

      # ==== Matrix ===== #
      "${matrixDomain}" = (mkProxyConfig { limitGeo = false; }) // {
        locations."/" = locationProxyPass;
      };
      "${matrixAuthDomain}" = (mkProxyConfig { limitGeo = false; }) // {
        locations."/" = locationProxyPass;
        locations."^~ /livekit/sfu/" = locationProxyPass // {
          extraConfig = mkAfter ''
            proxy_send_timeout 120;
            proxy_read_timeout 120;
            proxy_buffering off;

            proxy_set_header Accept-Encoding gzip;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
          '';
          priority = 400;
        };
      };

      # ==== Matrix Web client ==== #
      "element.${domain}" = (mkProxyConfig { }) // {
        locations."/" = locationProxyPass;
      };

      # NOTE: This is not verified and used
      "netbrid.${domain}" = {
        http2 = true;
        forceSSL = true;
        useACMEHost = domain;
        extraConfig = ''
          ${geoIpConfig}
        '';

        locations."/" = {
          proxyWebsockets = true;
          proxyPass = "https://${dn-server-ip}";
          extraConfig = ''
            proxy_ssl_server_name on;
          '';
        };

        locations."/management.ManagementService/".extraConfig = ''
          grpc_pass grpcs://${dn-server-ip};
          grpc_set_header Host netbird.${domain};
          grpc_ssl_name netbird.${domain};
          grpc_ssl_server_name on;
        '';

        locations."/signalexchange.SignalExchange/".extraConfig = ''
          grpc_pass grpcs://${dn-server-ip};
          grpc_set_header Host netbird.${domain};
          grpc_ssl_name netbird.${domain};
          grpc_ssl_server_name on;
        '';
      };
    };
  };
}
