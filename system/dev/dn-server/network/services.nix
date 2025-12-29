{
  config,
  lib,
  helper,
  ...
}:
let
  inherit (config.systemConf) username security;
  inherit (lib) concatStringsSep;
  inherit (helper.nftables) mkElementsStatement;

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

  kube = {
    ip = "10.10.0.1/24";
    range = "10.10.0.0/24";
    interface = "wg1";
    port = 51821;
    masterIP = "10.10.0.1";
    masterHostname = "api-kube.${config.networking.domain}";
    masterAPIServerPort = 6443;
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
  networking = {
    nat = {
      enable = true;
      enableIPv6 = true;
      externalInterface = ethInterface;
      internalInterfaces = [
        personal.interface
        kube.interface
      ];
    };

    firewall = {
      allowedUDPPorts = [
        53
        personal.port
        kube.port
        25565
        kube.masterAPIServerPort
        5359
      ];
      allowedTCPPorts = sshPorts ++ [
        53
        25565
        kube.masterAPIServerPort
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
              type filter hook input priority 0; policy drop;

              iif lo accept

              meta nftrace set 1
              meta l4proto { icmp, ipv6-icmp } accept

              ct state vmap { invalid : drop, established : accept, related : accept }

              udp dport 53 accept
              tcp dport 53 accept

              tcp dport { ${sshPortsString} } jump ssh-filter

              iifname { ${ethInterface}, ${personal.interface}, ${kube.interface} } udp dport { ${toString personal.port}, ${toString kube.port} } accept
              iifname ${personal.interface} ip saddr ${personal.ip} jump wg-subnet
              iifname ${kube.interface} ip saddr ${kube.ip} jump kube-filter

              drop
            }

            chain output {
              type filter hook output priority 0; policy drop;

              iif lo accept

              # Allow DNS qeury
              udp dport 53 accept
              tcp dport 53 accept

              meta skuid ${toString config.users.users.systemd-timesync.uid} accept

              ct state vmap { invalid : drop, established : accept, related : accept }
              ip saddr != @restrict_source_ips accept

              ip daddr @${security.rules.setName} accept
              ip6 daddr @${security.rules.setNameV6} accept

              counter log prefix "OUTPUT-DROP: " flags all drop
            }

            chain ssh-filter {
              ip saddr { ${allowedSSHIPs} } accept
              counter reject
            }

            chain forward {
              type filter hook forward priority 0; policy drop;

              meta l4proto { icmp, ipv6-icmp } accept

              iifname ${personal.interface} ip saddr ${personal.ip} jump wg-subnet
              iifname ${kube.interface} ip saddr ${kube.ip} jump kube-filter

              counter
            }

            chain kube-filter {
              ip saddr ${kube.ip} ip daddr ${kube.ip} accept
              counter drop
            }

            chain wg-subnet {
              ip saddr ${personal.full} accept
              ip saddr ${personal.restrict} ip daddr ${personal.range} accept
              counter drop
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
          peers = builtins.map (r: {
            inherit (r) publicKey allowedIPs;
          }) (fullRoute ++ meshRoute);
        };

        ${kube.interface} = {
          ips = [ kube.ip ];
          listenPort = kube.port;
          privateKeyFile = config.sops.secrets."wireguard/privateKey".path;
          peers = [ ];
        };
      };
    };

    extraHosts = "${kube.masterIP} ${kube.masterHostname}";
  };

  services = {
    dbus.enable = true;
    blueman.enable = true;

    postgresql = {
      enable = lib.mkDefault true;
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

    openssh = {
      enable = true;
      ports = sshPorts;
      settings = {
        PasswordAuthentication = false;
        UseDns = false;
        PermitRootLogin = "yes";
      };
    };

    powerdns = {
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
      secretFile = config.sops.secrets.powerdns.path;
    };

    pdns-recursor = {
      enable = true;
      forwardZones = {
        "${config.networking.domain}." = "127.0.0.1:5359";
        "pre7780.dn." = "127.0.0.1:5359";
        "test.local." = "127.0.0.1:5359";
      };
      forwardZonesRecurse = {
        # ==== Rspamd DNS ==== #
        "multi.uribl.com." = "168.95.1.1";
        "score.senderscore.com." = "168.95.1.1";
        "list.dnswl.org." = "168.95.1.1";
        "dwl.dnswl.org." = "168.95.1.1";

        # ==== Others ==== #
        "tw." = "168.95.1.1";
        "." = "8.8.8.8";
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

    dnsdist = {
      enable = true;
      extraConfig = ''
        newServer("127.0.0.1:${toString config.services.pdns-recursor.dns.port}")
        addDOHLocal("0.0.0.0:8053", nil, nil, "/", { reusePort = true })
        getPool(""):setCache(newPacketCache(65535, {maxTTL=86400, minTTL=0, temporaryFailureTTL=60, staleTTL=60, dontAge=false}))
      '';
    };

    powerdns-admin = {
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

    xserver = {
      enable = false;
      xkb.layout = "us";
    };
  };

  systemd.services.pdns-recursor.before = [ "acme-setup.service" ];
  systemd.services.pdns.before = [ "acme-setup.service" ];

  users.users = {
    root.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJSAOufpee7f8D8ONIIGU3qsN+8+DGO7BfZnEOTYqtQ5 danny@pre7780.dn"
    ];

    "${username}".openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJSAOufpee7f8D8ONIIGU3qsN+8+DGO7BfZnEOTYqtQ5 danny@pre7780.dn"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJFQA42R3fZmjb9QnUgzzOTIXQBC+D2ravE/ZLvdjoOQ danny@lap.dn"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILSHkPa6vmr5WBPXAazY16+Ph1Mqv9E24uLIf32oC2oH danny@phone.dn"
    ];
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
            "${config.security.pki.caBundle}:/etc/ca.crt:ro"
          ];
          environment = {
            NODE_EXTRA_CA_CERTS = "/etc/ca.crt";
          };
        };
      };
    };
  };

  systemd.services.raspamd-trainer = {
    after = [ "pdns-recursor.service" ];
  };

  services.nginx.virtualHosts = {
    "dns.${config.networking.domain}" = {
      enableACME = true;
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
    "powerdns.${config.networking.domain}" = {
      enableACME = true;
      forceSSL = true;
      locations."/api".proxyPass = "http://127.0.0.1:8081";
      locations."/".proxyPass = "http://127.0.0.1:8000";
    };
    "uptime.${config.networking.domain}" = {
      enableACME = true;
      forceSSL = true;
      locations."/".proxyPass = "http://localhost:3001";
    };
  };

  nix.settings.trusted-users = [
    username
  ];
}
