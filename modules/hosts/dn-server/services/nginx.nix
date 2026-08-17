{ config, ... }:
let
  inherit (config.flake.public.config) domain;
  inherit (config.flake.public.config.services) matrix mas;
in
{
  configurations.nixos.dn-server.module =
    {
      lib,
      pkgs,
      config,
      ...

    }:
    let
      inherit (builtins) fetchurl;
      inherit (lib)
        concatStringsSep
        optionalString
        mkBefore
        ;

      serverRules = config.server-rules;
      matrixDomain = matrix.hostname;
      matrixAuthDomain = mas.hostname;

      # ==== Allowed List ==== #
      accessAllowedVar = "$allow_access";
      ipAllowedVar = "$allow_ip";
      allowedCountries = serverRules.rule.default.allowed.countryCode;
      allowedIPs = serverRules.rule.default.allowed.ipv4 ++ [
        "127.0.0.1"
        "::1"
      ];

      # ==== geoip ==== #
      geoAllowedVar = "$allowed_country";
      geoDBCountry = fetchurl {
        url = "https://nextcloud.dnywe.com/s/geodb/download";
        sha256 = "sha256:0ir3bmni7756zfma8xfr1bnbszsizaas4gs3sq4zd4qgjl3rhm66";
      };
      geoIpConfig = ''
        if (${geoAllowedVar} = 1) {
          set ${accessAllowedVar} 1;
        }
      '';

      mkLimitConfig =
        {
          limitGeo ? true,
        }:
        {
          useACMEHost = domain;

          extraConfig = mkBefore ''
            ${optionalString limitGeo geoIpConfig}

            if ($http_user_agent ~* "GPTBot") {
              set ${accessAllowedVar} 0;
            }

            if ($http_user_agent ~* "bot") {
              set ${accessAllowedVar} 0;
            }

            if (${ipAllowedVar} = 1) {
              set ${accessAllowedVar} 1;
            }

            if (${accessAllowedVar} = 0) {
              return 444;
            }
          '';
        };

      mkDenyConfig = {
        extraConfig = ''
          if (${ipAllowedVar} = 1) {
            set ${accessAllowedVar} 1;
          }

          if (${accessAllowedVar} = 0) {
            return 444;
          }
        '';
      };
    in
    {
      networking.firewall.allowedTCPPorts = [ 443 ];

      services.nginx = {
        enable = true;
        enableReload = true;
        clientMaxBodySize = "40m";
        mapHashMaxSize = 4096;
        additionalModules = with pkgs.nginxModules; [ geoip2 ];
        recommendedGzipSettings = true;
        recommendedOptimisation = true;
        recommendedTlsSettings = true;
        recommendedProxySettings = true;

        commonHttpConfig = ''
          proxy_headers_hash_max_size 1024;
          proxy_headers_hash_bucket_size 128;

          log_format main '$remote_addr - $remote_user [$time_local] '
                              '"$host" "$request" "$geoip2_country_code" "$geoip2_country_name" $status $body_bytes_sent '
                              'upstream_status=$upstream_status '
                              'upstream_addr=$upstream_addr '
                              '"$http_referer" "$http_user_agent"';

          map $status $log_444 {
            default 0;
            444     1;
          }

          access_log /var/log/nginx/access.log main if=$log_444;

          set_real_ip_from 127.0.0.1;
          set_real_ip_from 10.20.0.2;
          set_real_ip_from 10.10.0.2;
          set_real_ip_from ::1;

          real_ip_header CF-Connecting-IP;
          real_ip_recursive off;

          limit_req_zone $binary_remote_addr zone=raw_limit:10m rate=100r/s;
        '';

        appendHttpConfig = ''
          geoip2 ${geoDBCountry} {
            auto_reload 5m;
            $geoip2_country_code country iso_code;
            $geoip2_country_name country names en;
          }

          map $geoip2_country_code ${geoAllowedVar} {
            default 0;
            ${concatStringsSep "\n" (map (c: "${c} 1;") allowedCountries)}
          }

          geo ${ipAllowedVar} {
            default 0;
            ${concatStringsSep "\n" (map (v: "${v} 1;") allowedIPs)}
          }
        '';

        prependConfig = ''
          worker_processes auto;
          worker_rlimit_nofile 65535;
        '';

        eventsConfig = /* nginx */ ''
          worker_connections 65535;
        '';

        virtualHosts = {
          # === Default === #
          "default-ssl" = {
            default = true;
            forceSSL = true;
            useACMEHost = domain;

            locations."/" = {
              return = "444";
            };
          };

          # ==== Netbird ==== #
          "netbird.${domain}" = mkLimitConfig {
            limitGeo = true;
          };

          "nextcloud.${domain}" = mkDenyConfig;
          "login.${domain}" = mkDenyConfig;
          "actual.${domain}" = mkDenyConfig;
          "bitwarden.${domain}" = mkDenyConfig;
          "${domain}" = mkDenyConfig;
          "element.${domain}" = mkDenyConfig;
          "git.${domain}" = mkDenyConfig;
          "grafana.${domain}" = mkDenyConfig;
          "${matrixAuthDomain}" = mkDenyConfig;
          "${matrixDomain}" = mkDenyConfig;
          "metrics.${domain}" = mkDenyConfig;
          "ntfy.${domain}" = mkDenyConfig;
          "paperless.${domain}" = mkDenyConfig;
          "powerdns.${domain}" = mkDenyConfig;
          "talk.${domain}" = mkDenyConfig;
          "uptime.${domain}" = mkDenyConfig;
        };
      };
    };
}
