{
  config,
  lib,
  ...
}:
let
  cfg = config.dns-server;
in
with lib;
{
  options.dns-server = {
    enable = mkEnableOption "PowerDNS server and PowerDNS Recursor";
    openFirewall = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Open 53 port in firewall
      '';
    };

    webAdmin = {
      enable = mkEnableOption "Enable PowerDNS Admin";
      saltFile = mkOption {
        type = types.path;
        description = ''
          Slat value for serialization, can be generated with `openssl rand -hex 16`
        '';
      };
      apiSecretFile = mkOption {
        type = types.path;
        description = ''
          The file content should be
          ```
          YOUR_PASSWORD
          ```
        '';
      };
    };

  };

  config = mkIf cfg.enable {
    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [ 53 ];
      allowedUDPPorts = [ 53 ];
    };

    services = {
      powerdns = {
        enable = true;
        extraConfig = ''
          launch=gpgsql
          webserver-password=$WEB_PASSWORD
          api=yes
          api-key=$WEB_PASSWORD
          gpgsql-host=/var/run/postgresql
          gpgsql-dbname=pdns
          gpgsql-user=pdns
          webserver=yes
          local-port=5359
        '';
        secretFile = config.sops.secrets.powerdns.path;
      };

      pdns-recursor = {
        enable = true;
        forwardZones = {
          "net.dn" = "127.0.0.1:5359";
        };
        forwardZonesRecurse = {
          "" = "8.8.8.8;8.8.4.4";
        };
        dnssecValidation = "off";
        dns.allowFrom = [
          "127.0.0.0/8"
          "10.0.0.0/24"
          "192.168.100.0/24"
          "::1/128"
          "fc00::/7"
          "fe80::/10"
        ];
      };

      powerdns-admin = {
        enable = true;
        secretKeyFile = config.sops.secrets."powerdns-admin/secret".path;
        saltFile = config.sops.secrets."powerdns-admin/salt".path;
        config =
          # python
          ''
            import cachelib

            SESSION_TYPE = 'cachelib'
            SESSION_CACHELIB = cachelib.simple.SimpleCache()
            SQLALCHEMY_DATABASE_URI = 'postgresql://powerdnsadmin@/powerdnsadmin?host=localhost'
          '';
      };
    };
  };
}
