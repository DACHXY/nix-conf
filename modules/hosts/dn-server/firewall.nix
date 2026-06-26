{
  configurations.nixos.dn-server.module =
    { config, ... }:
    let
      inherit (builtins) concatStringsSep;
      inherit (config.server-rules.rule.default) allowed;
      sshPortsString = concatStringsSep ", " (map (p: toString p) config.services.openssh.ports);
      allowedSSHIPs = concatStringsSep ", " allowed.ipv4;
    in
    {
      networking.nftables = {
        enable = true;
        tables.filter = {
          family = "inet";
          content = ''
            chain input {
              type filter hook input priority -10; policy accept;

              iif lo accept
              meta l4proto { icmp, ipv6-icmp } accept
              ct state vmap { invalid : drop, established : accept, related : accept }

              tcp dport { ${sshPortsString} } jump ssh-filter
            }

            chain ssh-filter {
              ip saddr { ${allowedSSHIPs} } accept

              limit rate 30/minute log prefix "SSH-DROP: "
              drop
            }
          '';
        };
      };
    };
}
