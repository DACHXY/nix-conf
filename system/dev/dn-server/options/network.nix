{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) mkOption types concatStringsSep;
  cfg = config.systemConf.security;
in
{
  options.systemConf.security = {
    allowedDomains = mkOption {
      type = with types; listOf str;
      description = "Domains that allowed to query dns.";
      default = [ ];
    };
    rules = {
      setName = mkOption {
        type = with types; str;
        default = "allowed_output_ips";
        readOnly = true;
      };
      setNameV6 = mkOption {
        type = with types; str;
        default = "allowed_output_ipv6";
        readOnly = true;
      };
    };
    dnsIPs = mkOption {
      type = with types; listOf str;
      description = "External DNS server to use";
      default = [ "8.8.8.8" ];
    };
    allowedIPs = mkOption {
      type = with types; listOf str;
      description = "IPv4 that allowed to request.";
      default = [ ];
    };
    allowedIPv6 = mkOption {
      type = with types; listOf str;
      description = "IPv6 that allowed to request.";
      default = [ ];
    };
    sourceIPs = mkOption {
      type = with types; listOf str;
      description = "Source IPs to restrict.";
      default = [ ];
    };
  };

  config = {
    environment.systemPackages = with pkgs; [
      ipset
    ];

    systemd.timers.fetch-allowed-domains = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = 10;
        OnUnitActiveSec = 360;
      };
    };

    systemd.services.fetch-allowed-domains = {
      path = with pkgs; [
        nftables
        dig.dnsutils
      ];
      after = [ "network.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.writeShellScript "fetch-allowed-domains" ''
          DOMAINS=(${toString (map (x: ''"${x}"'') cfg.allowedDomains)})
          SETNAME="inet filter ${cfg.rules.setName}"

          nft flush set $SETNAME
          nft add element $SETNAME { ${concatStringsSep "," cfg.allowedIPs} }

          for domain in "''${DOMAINS[@]}"; do
            ips=$(dig +short A $domain | grep -E '^[0-9.]+$')
            for ip in $ips; do
              nft add element $SETNAME { $ip }
              echo "Added $ip for $domain"
            done
          done
        ''}";
        Type = "oneshot";
      };
    };
  };
}
