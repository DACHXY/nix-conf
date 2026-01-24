{
  config,
  lib,
  helper,
  ...
}:
let
  inherit (builtins) concatStringsSep;
  inherit (config.systemConf) security domain;
  inherit (lib) mkForce;
  inherit (helper.nftables) mkElementsStatement;

  netbirdCfg = config.services.netbird;

  ethInterface = "enp0s31f6";
  sshPorts = [ 30072 ];
  sshPortsString = concatStringsSep ", " (map (p: toString p) sshPorts);

  personal = {
    inherit (config.networking) domain;
    ip = "10.0.0.1/24";
    interface = "wg0";
    port = 51820;
    range = "10.0.0.0/24";
    full = "10.0.0.1/25";
    restrict = "10.0.0.128/25";
  };

  infra = {
    ip = "10.10.0.2/32";
    interface = "wg1";
    range = "10.10.0.0/24";
  };

  allowedSSHIPs = concatStringsSep ", " [
    "122.117.215.55"
    "192.168.100.1/24"
    personal.range
  ];

  fullRoute = [
    {
      # Jonly
      dns = "jonly";
      publicKey = "GAayY6p8ST3I66kFSGY3seaHhfkrc6atcrFu2C9BDDs=";
      allowedIPs = [ "10.0.0.5/32" ];
    }
    {
      dns = "jonly-mac";
      publicKey = "jPmeA0WH3vQw/PDNdJwYLfE7Ibl5oZGuta9UkZNEyTk=";
      allowedIPs = [ "10.0.0.9/32" ];
    }
    {
      # YC
      dns = "yc";
      publicKey = "5LfmjAg07ixmBCcsEn319UHqMRO3AdusXsoibGUqfQE=";
      allowedIPs = [ "10.0.0.7/32" ];
    }
    {
      # Tommy
      dns = "tommy";
      publicKey = "AxujfkiHLj09LoAXZl7yUf3fzyjorKOg8CfcJJvr2HQ=";
      allowedIPs = [ "10.0.0.8/32" ];
    }
  ];

  meshRoute = [
    {
      # pre7780.dn
      dns = "pre7780";
      publicKey = "WvvBRGbWUMUhSgodZNlhglacsWhMOTdHhJxcf81kTmQ=";
      allowedIPs = [ "10.0.0.130/32" ];
    }
    {
      # Skydrive
      dns = "skydrive";
      publicKey = "GceSQwI7XqYQw2oPmquuKdPqmt6KsYnoGuFoiaKRb0E=";
      allowedIPs = [ "10.0.0.132/32" ];
    }
    {
      # ken
      dns = "phone.ken";
      publicKey = "knRpD7qb2JejioJBP5HZgWCrDEOWUq27+ueWPYwnWws=";
      allowedIPs = [ "10.0.0.134/32" ];
    }
    {
      # lap.dn
      dns = "lap";
      publicKey = "Cm2AZU+zlv+ThMqah6WiLVxgPNvMHm9DEGd4PfywNWU=";
      allowedIPs = [ "10.0.0.135/32" ];
    }
    {
      # justin03
      dns = "justin";
      publicKey = "WOze/PPilBPqQudk1D4Se34zWV3UghKXWTG6M/f7bEM=";
      allowedIPs = [ "10.0.0.136/32" ];
    }
    {
      # ahhaha
      dns = "ahhaha";
      publicKey = "PGBqCPLxaFd/+KqwrjF6B6lqxvpPKos0sst5gk8p8Bo=";
      allowedIPs = [ "10.0.0.137/32" ];
    }
    {
      # oreo
      dns = "oreo";
      publicKey = "GXHRZ9DmVg7VtuJdvcHOGFCuFqH2Kd/c+3unrq7e5SE=";
      allowedIPs = [ "10.0.0.139/32" ];
    }
    {
      # phone.dn
      dns = "phone";
      publicKey = "XiR4NZLdHyOvzt+fdYoFDW2s/Su8nlz8UgrVPLISdBY=";
      allowedIPs = [ "10.0.0.140/32" ];
    }
    {
      # kavic
      dns = "kavic";
      publicKey = "VVzGcHjSo6QkvN6raS9g/NYLIrZ1xzxdnEronQaTIHs=";
      allowedIPs = [ "10.0.0.141/32" ];
    }
    {
      dns = "yc-mesh";
      publicKey = "dKcEjRq9eYA8rXVfispNoKEbrs9R3ZIVlQi5AXfFch8=";
      allowedIPs = [ "10.0.0.142/32" ];
    }
    {
      dns = "jonly-mesh";
      publicKey = "EyRL+iyKZJaqz9DXVsH2Ne/wVInx5hg9oQARrXP3/k0=";
      allowedIPs = [ "10.0.0.143/32" ];
    }
    {
      dns = "tommy-mesh";
      publicKey = "oCRNCyg0bw6W6W87XQ4pIUW+WFi/bx9MG4cIwE23GxI=";
      allowedIPs = [ "10.0.0.144/32" ];
    }
    {
      # ken
      dns = "pc.ken";
      publicKey = "ERLMpSbSIYRN5HoKmvsk2852/aAvzjvMV7tOs0oupxI=";
      allowedIPs = [ "10.0.0.145/32" ];
    }
    {
      # Skydrive Lap
      dns = "skydrive-mesh";
      publicKey = "MK6UX8WadSbDXI3919F5EarYlZHjFNbHwYJH8Ub/YXk=";
      allowedIPs = [ "10.0.0.146/32" ];
    }
    {
      # Skydrive Phone
      dns = "skydrive-mesh-phone";
      publicKey = "K6Pd69/Hfu4ceCAp/JbeEL2QQ+/4ohugW1lAOxHFKDA=";
      allowedIPs = [ "10.0.0.147/32" ];
    }
    {
      # GCP
      dns = "gcp";
      publicKey = "5th0G9c7vHrhcByvPJAbrn2LXjLPqDEMsHzda0FGUTQ=";
      allowedIPs = [ "10.0.0.148/32" ];
    }
    # DN Win
    {
      dns = "win";
      publicKey = "LuKw1w879a3kRaBK+faToVmb9uLhbj6tf/DstgMMJzQ=";
      allowedIPs = [ "10.0.0.149/32" ];
    }
  ];
in
{
  systemConf.security.allowedIPs = [
    "10.10.0.0/24"
    "10.0.0.0/24"
  ];

  networking = {
    nat = {
      enable = true;
      enableIPv6 = true;
      externalInterface = ethInterface;
      internalInterfaces = [
        personal.interface
      ];
    };

    firewall = {
      allowedUDPPorts = [
        53
        personal.port
        5359
      ];
      allowedTCPPorts = sshPorts ++ [
        53
        5359
      ];
    };

    nftables = {
      enable = true;
      tables = {
        filter = {
          family = "inet";
          content = ''
            set restrict_source_ips {
              type ipv4_addr
              flags interval
              ${mkElementsStatement security.sourceIPs}
            }

            set ${security.rules.setName} {
              type ipv4_addr
              flags interval
              ${mkElementsStatement security.allowedIPs}
            }

            set ${security.rules.setNameV6} {
              type ipv6_addr
              flags interval
              ${mkElementsStatement security.allowedIPv6}
            }

            chain input {
              type filter hook input priority -10; policy drop;

              iif lo accept
              meta l4proto { icmp, ipv6-icmp } accept
              ct state vmap { invalid : drop, established : accept, related : accept }

              tcp dport { ${sshPortsString} } jump ssh-filter

              iifname { ${personal.interface}, ${infra.interface}, ${netbirdCfg.clients.wt0.interface} } accept
            }

            chain output {
              type filter hook output priority -10; policy drop;

              iif lo accept
              ct state vmap { invalid : drop, established : accept, related : accept }

              # Time Sync
              meta skuid ${toString config.users.users.systemd-timesync.uid} accept

              # VPN
              oifname { ${personal.interface}, ${infra.interface}, ${netbirdCfg.clients.wt0.interface} } accept

              # Allow DNS qeury
              udp dport 53 accept
              tcp dport 53 accept

              # UDP Hole Punching
              meta mark 0x1bd00 accept

              # DHCP
              udp sport 68 udp dport 67 accept

              # Allowed IPs
              ip saddr != @restrict_source_ips accept
              ip daddr @${security.rules.setName} accept
              ip6 daddr @${security.rules.setNameV6} accept

              counter log prefix "OUTPUT-DROP: " flags all drop
            }

            chain ssh-filter {
              iifname { ${personal.interface}, ${infra.interface}, ${netbirdCfg.clients.wt0.interface} } tcp dport { ${sshPortsString} } accept
              ip saddr { ${allowedSSHIPs} } tcp dport { ${sshPortsString} } accept

              counter log prefix "SSH-DROP: " flags all drop
            }

            chain postrouting {
              type nat hook postrouting priority 100; policy accept;
              oifname ${ethInterface} masquerade
            }
          '';
        };
      };
    };

    wireguard = {
      enable = true;
      interfaces = {
        ${personal.interface} = {
          ips = [ personal.ip ];
          listenPort = personal.port;
          privateKeyFile = config.sops.secrets."wireguard/privateKey".path;
          peers = map (r: {
            inherit (r) publicKey allowedIPs;
          }) (fullRoute ++ meshRoute);
        };
      };
    };
  };

  services = {
    dbus.enable = true;
    blueman.enable = true;

    openssh = {
      enable = true;
      ports = mkForce sshPorts;
      settings = {
        PasswordAuthentication = false;
        UseDns = false;
        PermitRootLogin = "yes";
      };
    };

    xserver = {
      enable = false;
      xkb.layout = "us";
    };
  };

  systemConf.security = {
    allowedDomains = [
      "registry-1.docker.io"
    ];
  };

  virtualisation = {
    oci-containers = {
      containers = {
        uptime-kuma = {
          extraOptions = [ "--network=host" ];
          image = "louislam/uptime-kuma:2";
          volumes = [
            "/var/lib/uptime-kuma:/app/data"
          ];
        };
      };
    };
  };

  systemd.services.rspamd-trainer = {
    after = [ "pdns-recursor.service" ];
  };

  services.nginx.virtualHosts."uptime.${domain}" = {
    useACMEHost = domain;
    forceSSL = true;
    locations."/".proxyPass = "http://127.0.0.1:3001";
  };
}
