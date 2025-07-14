{
  settings,
  config,
  pkgs,
  lib,
  ...
}:

let
  username = settings.personal.username;
  ethInterface = "enp0s31f6";
  sshPorts = [ 30072 ];
  sshPortsString = builtins.concatStringsSep ", " (builtins.map (p: builtins.toString p) sshPorts);

  getCleanAddress =
    ip:
    with builtins;
    let
      result = replaceStrings [ "/24" "/32" ] [ "" "" ] ip;
    in
    result;

  getReverseFilename =
    ip:
    with builtins;
    with lib.lists;
    with lib.strings;
    let
      octets = take 3 (splitString "." (getCleanAddress ip));
      reversedFilename = "db." + (concatStringsSep "." (reverseList octets));
    in
    reversedFilename;

  getSubAddress =
    ip:
    with builtins;
    with lib.lists;
    with lib.strings;
    let
      octets = reverseList (splitString "." (getCleanAddress ip));
      sub = head octets;
    in
    sub;

  reverseIP =
    ip:
    with builtins;
    with lib.lists;
    with lib.strings;
    let
      octets = splitString "." (getCleanAddress ip);
      reversedIP = (concatStringsSep "." (reverseList octets)) + ".in-addr.arpa";
    in
    reversedIP;

  reverseZone =
    ip:
    with builtins;
    with lib.lists;
    with lib.strings;
    let
      octets = take 3 (splitString "." (getCleanAddress ip));
      reversedZone = (concatStringsSep "." (reverseList octets)) + ".in-addr.arpa";
    in
    reversedZone;

  personal = {
    ip = "10.0.0.1/24";
    interface = "wg0";
    port = 51820;
    domain = config.networking.domain;
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
      dns = "rasp";
      publicKey = "z+2d+4FhSClGlSiAtaGnTgU6utxElfdRqiwPpCJFRn8=";
      allowedIPs = [ "10.0.0.145/32" ];
    }
  ];

  dnsRecords =
    with builtins;
    concatStringsSep "\n" (
      map (
        r:
        let
          ip = getCleanAddress (elemAt r.allowedIPs 0);
        in
        ''
          ${r.dns}    IN     A      ${ip}
        ''
      ) (fullRoute ++ meshRoute)
    );

  dnsReversedRecords =
    with builtins;
    concatStringsSep "\n" (
      map (
        r:
        let
          reversed = getSubAddress (getCleanAddress (elemAt r.allowedIPs 0));
        in
        ''
          ${reversed}   IN     PTR    ${r.dns}.${personal.domain}.
        ''
      ) (fullRoute ++ meshRoute)
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
        25565
        kube.masterAPIServerPort
      ];
      allowedTCPPorts = sshPorts ++ [
        53
        25565
        kube.masterAPIServerPort
      ];
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
          privateKeyFile = config.sops.secrets."wireguard/privateKey".path;
          peers = builtins.map (r: {
            publicKey = r.publicKey;
            allowedIPs = r.allowedIPs;
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
      forwarders = [
        "8.8.8.8"
        "8.8.4.4"
      ];
      cacheNetworks = [
        "127.0.0.0/24"
        "::1/128"
        personal.range
        kube.range
      ];
      zones = {
        "${personal.domain}" = {
          master = true;
          allowQuery = [
            "127.0.0.0/24"
            "::1/128"
            personal.range
            kube.range
          ];
          file =
            let
              serverIP = getCleanAddress personal.ip;
              kubeIP = getCleanAddress kube.ip;
              origin = "${personal.domain}.";
              hostname = config.networking.hostName;
            in
            pkgs.writeText "db.${personal.domain}" ''
              $ORIGIN ${origin}
              $TTL    1h
              @           IN     SOA    dns.${origin} admin.dns.${origin} (
                                            1     ; Serial
                                            3h    ; Refresh
                                            1h    ; Retry
                                            1w    ; Expire
                                            1h)   ; Negative Cache TTL
                          IN     NS     dns.${origin}
              @           IN     A      ${serverIP}
                          IN     AAAA   fe80::3319:e2bb:fc15:c9df
              @           IN     MX     10 mail.${origin}
                          IN     TXT    "v=spf1 mx"
              dns         IN     A      ${serverIP}
              files       IN     A      ${serverIP}
              nextcloud   IN     A      ${serverIP}
              bitwarden   IN     A      ${serverIP}
              ca          IN     A      ${serverIP}
              ${hostname} IN     A      ${serverIP}
              mail        IN     A      ${serverIP}
              api-kube    IN     A      ${kubeIP}
              vmail       IN     A      10.0.0.130
              ${dnsRecords}
            '';
        };

        "${reverseZone personal.ip}" = {
          master = true;
          allowQuery = [
            "127.0.0.0/24"
            "::1/128"
            personal.range
            kube.range
          ];
          file =
            let
              serverIP = getSubAddress personal.ip;
              hostname = config.networking.hostName;
            in
            pkgs.writeText "${getReverseFilename personal.ip}" ''
              $TTL 86400
              @           IN     SOA    dns.${personal.domain}. admin.dns.${personal.domain}. (
                                            1     ; Serial
                                            3h    ; Refresh
                                            1h    ; Retry
                                            1w    ; Expire
                                            1h)   ; Negative Cache TTL
                          IN     NS     dns.${personal.domain}.

              ${serverIP} IN     PTR    dns.${personal.domain}.
              ${serverIP} IN     PTR    mail.${personal.domain}.
              ${serverIP} IN     PTR    ${hostname}.${personal.domain}.
              ${serverIP} IN     PTR    nextcloud.${personal.domain}.
              ${serverIP} IN     PTR    files.${personal.domain}.
              ${serverIP} IN     PTR    bitwarden.${personal.domain}.
              ${serverIP} IN     PTR    ca.${personal.domain}.
              130         IN     PTR    vmail.${personal.domain}.
              ${dnsReversedRecords}
            '';

        };
      };
    };

    xserver = {
      enable = false;
      xkb.layout = "us";
    };
  };

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

  nix.settings.trusted-users = [
    username
  ];
}
