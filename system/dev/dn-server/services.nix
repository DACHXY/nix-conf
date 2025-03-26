{ username, pkgs, ... }:

let
  ethInterface = "enp0s31f6";
  wlInterface = "wlp0s20f3";
  sshPorts = [ 30072 ];
  sshPortsString = builtins.concatStringsSep ", " (builtins.map (p: builtins.toString p) sshPorts);
  personal = {
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
  };

  allowedSSHIPs = builtins.concatStringsSep ", " [
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
      dns = "ken";
      publicKey = "iWjBGArok96mFzFHXYjTxwyRHGQ4U0V77txoi6WS2QU=";
      allowedIPs = [ "10.0.0.134/32" ];
    }
    {
      # lap.dn
      dns = "lap";
      publicKey = "Cm2AZU+zlv+ThMqah6WiLVxgPNvMHm9DEGd4PfywNWU=";
      allowedIPs = [ "10.0.0.135/32" ];
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
  ];

  dnsRecords =
    with builtins;
    concatStringsSep "\n" (
      map (r: ''
        ${r.dns}    IN     A      ${replaceStrings [ "/32" ] [ "" ] (elemAt r.allowedIPs 0)}
      '') (fullRoute ++ meshRoute)
    );
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
      ];
      allowedTCPPorts = sshPorts ++ [ 53 ];
    };

    nftables = {
      enable = true;
      ruleset = ''
        table inet wg-filter {
          chain input {
            type filter hook input priority 0; policy drop;

            iif lo accept

            meta nftrace set 1
            meta l4proto { icmp, ipv6-icmp } accept

            ct state vmap { invalid : drop, established : accept, related : accept }

            udp dport 53 accept
            tcp dport 53 accept

            tcp dport { ${sshPortsString} } jump ssh-filter

            iifname { ${ethInterface}, ${personal.interface}, ${kube.interface} } udp dport { ${builtins.toString personal.port}, ${builtins.toString kube.port} } accept
            iifname ${personal.interface} ip saddr ${personal.ip} jump wg-subnet
            iifname ${kube.interface} ip saddr ${kube.ip} jump kube-filter

            counter reject
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
        }
      '';
    };

    wireguard = {
      enable = true;
      interfaces = {
        ${personal.interface} = {
          ips = [ personal.ip ];
          listenPort = personal.port;
          privateKeyFile = "/etc/wireguard/privatekey";
          peers = builtins.map (r: {
            publicKey = r.publicKey;
            allowedIPs = r.allowedIPs;
          }) (fullRoute ++ meshRoute);
        };

        ${kube.interface} = {
          ips = [ kube.ip ];
          listenPort = kube.port;
          privateKeyFile = "/etc/wireguard/privatekey";
          peers = [ ];
        };
      };
    };
  };

  services = {
    dbus.enable = true;

    blueman.enable = true;

    openssh = {
      enable = true;
      ports = sshPorts;
      settings = {
        PasswordAuthentication = false;
        UseDns = false;
        PermitRootLogin = "yes";
      };
    };

    bind = {
      enable = true;
      cacheNetworks = [
        "127.0.0.0/24"
        "::1/128"
        personal.range
        kube.range
      ];
      zones = {
        "net.dn" = {
          master = true;
          allowQuery = [
            "127.0.0.0/24"
            "::1/128"
            personal.range
            kube.range
          ];
          file = pkgs.writeText "zone-net.dn" ''
            $ORIGIN net.dn.
            $TTL    1h
            @           IN     SOA    server hostmaster (
                                          1     ; Serial
                                          3h    ; Refresh
                                          1h    ; Retry
                                          1w    ; Expire
                                          1h)   ; Negative Cache TTL
                        IN     NS     server
                        IN     NS     phone
            @           IN     A      10.0.0.1
                        IN     AAAA   fe80::3319:e2bb:fc15:c9df
                        IN     MX     10 mail
                        IN     TXT    "v=spf1 mx"

            server      IN     A      10.0.0.1
            ${dnsRecords}
          '';
        };
      };
    };

    xserver = {
      enable = false;
      xkb.layout = "us";
    };

    # USB auto mount
    gvfs.enable = true;
    udisks2.enable = true;
    devmon.enable = true;
  };

  users.users = {
    root.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBzLpMKn0Q24ACC6k/7lOX0FIdcFhq15NY6849yROeUK danny@dn-pre7780"
    ];

    "${username}".openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJSAOufpee7f8D8ONIIGU3qsN+8+DGO7BfZnEOTYqtQ5 danny@pre7780.dn"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJFQA42R3fZmjb9QnUgzzOTIXQBC+D2ravE/ZLvdjoOQ danny@lap.dn"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILSHkPa6vmr5WBPXAazY16+Ph1Mqv9E24uLIf32oC2oH danny@phone.dn"
    ];
  };

  nix.settings.trusted-users = [
    username
  ];
}
