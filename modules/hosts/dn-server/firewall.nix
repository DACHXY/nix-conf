{ config, ... }:
let
  inherit (config.flake.public.config.machines) dn-cc;
in
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
            set ssh_allow_v4 {
              type ipv4_addr
              flags interval

              elements = {
                ${allowedSSHIPs}
              }
            }

            chain input {
              type filter hook input priority -10; policy accept;

              iif lo accept
              meta l4proto { icmp, ipv6-icmp } accept
              ct state vmap { invalid : drop, established : accept, related : accept }

              tcp dport { ${sshPortsString} } jump ssh-filter
              # Not the public MX - only dn-cc may relay SMTP here.
              tcp dport 25 jump smtp-filter
            }

            chain ssh-filter {
              ip saddr @ssh_allow_v4 accept

              limit rate 30/minute log prefix "SSH-DROP: "
              drop
            }

            chain smtp-filter {
              ip saddr ${dn-cc.ip} accept

              limit rate 10/minute log prefix "SMTP-DROP: "
              drop
            }
          '';
        };
      };
    };
}
