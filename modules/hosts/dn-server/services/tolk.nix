{ config, ... }:
let
  inherit (config.flake.public.config) domain;
in
{
  configurations.nixos.dn-server.module =
    {
      pkgs,
      lib,
      ...
    }:
    let
      inherit (lib) getExe;

      # Stalwart's internal JMAP/admin listener, see services/stalwart.nix.
      managementPort = 30093;
      # 3009x is the local-service range on this host (stalwart 30092-30097,
      # loki 30095, tempo 30098-30099); Tolk sits just above it.
      tolkPort = 30100;

      tolk = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
        pname = "tolk";
        version = "0.2.0";

        # Upstream ships a single static musl binary, no runtime deps.
        src = pkgs.fetchurl {
          url = "https://github.com/RBogie/tolk-jmap/releases/download/v${finalAttrs.version}/tolk-${finalAttrs.version}-linux-amd64";
          hash = "sha256-jhba8wAVowT0/AvMahMENiMQqJRCwKL9mLwi2yk0qr0=";
        };

        dontUnpack = true;
        dontStrip = true;

        installPhase = ''
          runHook preInstall
          install -Dm555 $src $out/bin/tolk
          runHook postInstall
        '';

        meta = {
          description = "Exchange ActiveSync server for JMAP mail servers";
          homepage = "https://github.com/RBogie/tolk-jmap";
          license = lib.licenses.agpl3Only;
          mainProgram = "tolk";
          platforms = [ "x86_64-linux" ];
        };
      });

      # Reverse-proxied by nginx as a JMAP-speaking loopback client: it sends
      # the device address on to Stalwart itself (X-Forwarded-For), and only
      # believes forwarding headers from nginx.
      proxyHeaders = ''
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $http_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
      '';
    in
    {
      systemd.services.tolk = {
        description = "Exchange ActiveSync bridge to Stalwart's JMAP";
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];

        environment = {
          LISTEN_ADDR = "127.0.0.1:${toString tolkPort}";
          # Loopback plain HTTP on purpose: going through the public name
          # would hairpin out through Cloudflare and hit the geo allow-list.
          JMAP_URL = "http://127.0.0.1:${toString managementPort}";
          PUBLIC_URL = "https://jmap.${domain}";
          TRUSTED_PROXIES = "127.0.0.1/32,::1/128";
          STATE_DB = "/var/lib/tolk/state.sqlite";
        };

        serviceConfig = {
          ExecStart = "${getExe tolk}";
          Restart = "on-failure";
          RestartSec = 5;

          DynamicUser = true;
          StateDirectory = "tolk";
          StateDirectoryMode = "0700";

          NoNewPrivileges = true;
          PrivateTmp = true;
          PrivateDevices = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectControlGroups = true;
          RestrictAddressFamilies = [
            "AF_INET"
            "AF_INET6"
            "AF_UNIX"
          ];
          RestrictNamespaces = true;
          LockPersonality = true;
          MemoryDenyWriteExecute = true;
          SystemCallArchitectures = "native";
          SystemCallFilter = [
            "@system-service"
            "~@privileged"
          ];
        };
      };

      services.nginx.virtualHosts."jmap.${domain}".locations = {
        # Exchange ActiveSync itself, plus Autodiscover so phones find their
        # way here with the server name alone. Everything else on this vhost
        # stays with Stalwart (see services/stalwart.nix). The keys are regex
        # locations: phones ask for /Microsoft-Server-ActiveSync and
        # /Autodiscover/Autodiscover.xml, and nginx prefix matching is
        # case-sensitive.
        "~* ^/Microsoft-Server-ActiveSync" = {
          proxyPass = "http://127.0.0.1:${toString tolkPort}";
          # `recommendedProxySettings` would append this host's peer (dn-cc)
          # to X-Forwarded-For; the header has to arrive with the device
          # address only, so the proxy headers are spelled out here.
          recommendedProxySettings = false;
          extraConfig = proxyHeaders;
        };
        "~* ^/autodiscover/" = {
          proxyPass = "http://127.0.0.1:${toString tolkPort}";
          recommendedProxySettings = false;
          extraConfig = proxyHeaders;
        };
      };
    };
}
