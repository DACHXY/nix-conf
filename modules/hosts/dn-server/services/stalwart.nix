{ config, ... }:
let
  inherit (config.flake.public.config) domain;
  inherit (config.flake.public.config.services.openldap) olcDomain;
  inherit (config.flake.public.config.services) stalwart;
  inherit (config.flake.public.config.machines) dn-cc;
in
{
  configurations.nixos.dn-server.module =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib) getExe concatMapStringsSep;

      package = pkgs.stalwart_1_0;
      # Postgres role; the store itself lives in `storeDatabase`, owned by it.
      dbName = "stalwart";
      storeDatabase = "stalwart_v1";
      fqdn = "jmap.${domain}";
      managementPort = 30093;
      # Stalwart's OtelHttp tracer posts here; Alloy on this host receives it
      # and forwards logs to the local Loki and spans to the local Tempo. Same
      # number as dn-cc's receiver: the two hosts never share a loopback.
      otlpPort = stalwart.otlpPort;
      certDir = config.security.acme.certs."${domain}".directory;

      getCredFile = var_name: "/run/credentials/stalwart.service/${var_name}";

      configJson = pkgs.writeText "stalwart-config.json" (
        builtins.toJSON {
          "@type" = "PostgreSql";
          host = "127.0.0.1";
          port = 5432;
          database = storeDatabase;
          authUsername = dbName;
          poolMaxConnections = 10;
        }
      );

      plan = [
        {
          "@type" = "upsert";
          object = "Certificate";
          matchOn = [ "subjectAlternativeNames" ];
          value = {
            cert-main = {
              certificate = {
                "@type" = "File";
                filePath = "${certDir}/fullchain.pem";
              };
              privateKey = {
                "@type" = "File";
                filePath = "${certDir}/key.pem";
              };
              subjectAlternativeNames = {
                "${domain}" = true;
                "*.${domain}" = true;
              };
            };
          };
        }
        {
          "@type" = "upsert";
          object = "Domain";
          matchOn = [ "name" ];
          value = {
            dom-main = {
              name = domain;
              certificateManagement = {
                "@type" = "Manual";
              };
              dkimManagement = {
                "@type" = "Manual";
              };
              dnsManagement = {
                "@type" = "Manual";
              };
              subAddressing = {
                "@type" = "Disabled";
              };
            };
          };
        }
        {
          "@type" = "update";
          object = "SystemSettings";
          value = {
            defaultHostname = fqdn;
            defaultDomainId = "#dom-main";
            defaultCertificateId = "#cert-main";
          };
        }
        {
          "@type" = "upsert";
          object = "Directory";
          value = {
            dir-ldap = {
              description = "ldap";
              "@type" = "Ldap";
              url = "ldap://127.0.0.1";
              timeout = 10000;
              baseDn = olcDomain;
              bindDn = "cn=replicator,${olcDomain}";
              bindSecret = {
                "@type" = "File";
                filePath = getCredFile "ldap_replicator_password";
              };
              filterLogin = "(|(uid=?)(mail=?)(mailRoutingAddress=?))";
              filterRecipient = "(|(mail=?)(mailRoutingAddress=?))";
              attrEmail.mail = true;
              attrSecret.userPassword = true;
            };
          };
        }
        {
          "@type" = "update";
          object = "Authentication";
          value = {
            directoryId = "#dir-ldap";
          };
        }
        {
          "@type" = "update";
          object = "OidcProvider";
          value = {
            # Stalwart rejects OAuth clients whose client_id is an HTTPS
            # metadata document by default; such clients are shown as
            # unverified on the consent screen.
            clientMetadataDocuments = "any";
          };
        }
        {
          "@type" = "upsert";
          object = "MtaRoute";
          matchOn = [ "name" ];
          value = {
            relay-dncc = {
              name = "relay-dncc";
              "@type" = "Relay";
              host = dn-cc.ip;
              port = 25;
              protocol = "smtp";
              implicitTls = false;
              allowInvalidCerts = true;
            };
          };
        }
        {
          "@type" = "update";
          object = "MtaOutboundStrategy";
          value = {
            # "match" omitted entirely - an explicit empty list was
            # rejected by the patch validator.
            route = {
              "else" = "'relay-dncc'";
            };
          };
        }
        {
          # Bulwark may make cross-origin JMAP calls to this host directly.
          "@type" = "update";
          object = "Http";
          value.usePermissiveCors = true;
        }
        {
          # Auto-ban rules, off by default.
          "@type" = "update";
          object = "Security";
          value = {
            authBanRate = {
              count = 5;
              period = 600000; # 10m
            };
            authBanPeriod = 3600000; # 1h
            abuseBanRate = {
              count = 20;
              period = 60000; # 1m
            };
            abuseBanPeriod = 3600000; # 1h
            scanBanRate = {
              count = 5;
              period = 60000; # 1m
            };
            scanBanPeriod = 86400000; # 24h
          };
        }
        {
          "@type" = "update";
          object = "SpamSettings";
          value.enable = false;
        }
        {
          # Firewall restricts smtp:25 to dn-cc's IP only, so it's the only
          # "sender" this host sees - no SPF/PTR record to check against.
          "@type" = "update";
          object = "SenderAuth";
          value = {
            spfEhloVerify."else" = "disable";
            spfFromVerify."else" = "disable";
            dmarcVerify."else" = "disable";
            reverseIpVerify."else" = "disable";
          };
        }
        {
          # Stalwart generates DMARC/SPF/DKIM/TLS reports daily and mails them
          # to the report addresses published in each sender domain's DNS.
          # Those are the messages that were being handed to dn-cc and refused
          # with "relay-not-allowed": nothing on this host should send mail on
          # its own initiative. Same four switches as dn-cc (which already
          # disables them) so no host emits report mail.
          "@type" = "update";
          object = "DkimReportSettings";
          value.sendFrequency."else" = "disable";
        }
        {
          "@type" = "update";
          object = "SpfReportSettings";
          value.sendFrequency."else" = "disable";
        }
        {
          "@type" = "update";
          object = "DmarcReportSettings";
          value = {
            aggregateSendFrequency."else" = "disable";
            failureSendFrequency."else" = "disable";
          };
        }
        {
          "@type" = "update";
          object = "TlsReportSettings";
          value.sendFrequency."else" = "disable";
        }
        {
          # This host is the mailbox backend: the events that matter for
          # "what happened to mail of account X" (submission, queue, delivery
          # failures) are all emitted here, not on the dn-cc gateway. Same
          # pipeline as dn-cc's tracer-history; Alloy on this host listens on
          # the same loopback port and forwards to the local Loki.
          "@type" = "upsert";
          object = "Tracer";
          matchOn = [ "url" ];
          value = {
            tracer-history = {
              "@type" = "OtelHttp";
              url = "http://127.0.0.1:${toString otlpPort}/v1/logs";
              enableLogExporter = true;
              enableSpanExporter = false;
              # The include list below is the real filter; `trace` just keeps
              # the level check from dropping any of the listed events.
              level = "trace";
              eventsPolicy = "include";
              events = lib.genAttrs [
                # Every event of a session also carries the span keys
                # (remoteIp, remotePort, listenerId, localPort).
                "smtp.connection-start"
                "smtp.ehlo"
                "smtp.mail-from"
                "smtp.rcpt-to"
                "smtp.spf-ehlo-pass"
                "smtp.spf-ehlo-fail"
                "smtp.spf-from-pass"
                "smtp.spf-from-fail"
                "smtp.dkim-pass"
                "smtp.dkim-fail"
                "smtp.arc-pass"
                "smtp.arc-fail"
                "smtp.dmarc-pass"
                "smtp.dmarc-fail"
                "smtp.iprev-pass"
                "smtp.iprev-fail"
                "smtp.relay-not-allowed"
                "smtp.mailbox-does-not-exist"
                "smtp.mail-from-unauthenticated"
                "smtp.message-too-large"
                "smtp.rate-limit-exceeded"
                "smtp.rcpt-to-greylisted"
                "smtp.invalid-ehlo"
                "smtp.did-not-say-ehlo"
                "spam.classify"
                "queue.message-queued"
                "queue.authenticated-message-queued"
                "delivery.delivered"
                # Failures, so a per-account view can say why a message died;
                # each carries `from` (return path) and `to` (recipient).
                "delivery.failed"
                "delivery.dsn-perm-fail"
                "delivery.dsn-temp-fail"
                "delivery.rcpt-to-failed"
                "delivery.rcpt-to-rejected"
                "delivery.mx-lookup-failed"
                "delivery.null-mx"
                "delivery.connect-error"
                "delivery.greeting-failed"
                "delivery.ehlo-rejected"
                "delivery.double-bounce"
                "queue.quota-exceeded"
                "security.authentication-ban"
                "security.abuse-ban"
                "security.scan-ban"
                "security.ip-blocked"
              ] (_: true);
            };
          };
        }
        {
          # Spans for the Grafana traces view / Traces Drilldown (local Tempo).
          # Spans use the endpoint verbatim (the OTLP exporter only appends
          # /v1/traces when no path is given), so traces and logs need separate
          # tracers: this one logs nothing.
          "@type" = "upsert";
          object = "Tracer";
          matchOn = [ "url" ];
          value = {
            tracer-spans = {
              "@type" = "OtelHttp";
              url = "http://127.0.0.1:${toString otlpPort}/v1/traces";
              enableLogExporter = false;
              enableSpanExporter = true;
              # debug: one span per SMTP/JMAP session plus delivery stage.
              level = "debug";
              # Do not slow the mail path if the collector is unreachable.
              lossy = true;
              eventsPolicy = "exclude";
              events = { };
            };
          };
        }
        {
          # /metrics/prometheus is served on every `http` listener, and the
          # management listener below is already bound to 127.0.0.1:30093, so
          # the local Prometheus can scrape it without a dedicated listener or
          # an extra firewall opening. No auth: the bind address is the
          # access control.
          "@type" = "update";
          object = "Metrics";
          value = {
            prometheus = {
              "@type" = "Enabled";
            };
          };
        }
        {
          "@type" = "upsert";
          object = "NetworkListener";
          matchOn = [ "name" ];
          value = {
            smtp = {
              name = "smtp";
              protocol = "smtp";
              bind."0.0.0.0:25" = true;
            };
            imaps = {
              name = "imaps";
              protocol = "imap";
              bind."0.0.0.0:993" = true;
              useTls = true;
              implicitTls = true;
            };
            submissions = {
              name = "submissions";
              protocol = "smtp";
              bind."0.0.0.0:465" = true;
              useTls = true;
              implicitTls = true;
            };
            management = {
              name = "management";
              protocol = "http";
              bind."127.0.0.1:${toString managementPort}" = true;
              useTls = false;
            };
          };
        }
      ];

      planText = concatMapStringsSep "\n" (op: builtins.toJSON op) plan;
      planFile = pkgs.writeText "stalwart-plan.ndjson" planText;
    in
    {
      services.postgresql = {
        ensureUsers = [
          {
            name = dbName;
            ensureDBOwnership = true;
          }
        ];
        ensureDatabases = [ dbName ];
      };

      # Shared with dn-cc's syncrepl consumer, in the same secret.yaml.
      sops.secrets."openldap/replicatorPassword" = {
        owner = "stalwart";
        group = "stalwart";
        mode = "400";
      };

      sops.secrets."stalwart/adminPassword" = {
        owner = "stalwart";
        group = "stalwart";
        mode = "640";
      };

      sops.templates."stalwart-bootstrap.env" = {
        owner = "stalwart";
        content = ''
          STALWART_USER=admin
          STALWART_PASSWORD=${config.sops.placeholder."stalwart/adminPassword"}
        '';
      };

      sops.templates."stalwart-recovery-admin.env" = {
        owner = "stalwart";
        content = ''
          STALWART_RECOVERY_ADMIN=admin:${config.sops.placeholder."stalwart/adminPassword"}
        '';
      };

      users.groups.stalwart = { };
      users.users.stalwart = {
        isSystemUser = true;
        group = "stalwart";
        extraGroups = [ "acme" ];
      };

      networking.firewall.allowedTCPPorts = [
        25 # SMTP, relayed-only from dn-cc over WireGuard
        465 # Submissions (implicit TLS)
        993 # IMAPS (implicit TLS)
      ];

      systemd.services.stalwart = {
        description = "Stalwart Mail Server (backend)";
        wantedBy = [ "multi-user.target" ];
        after = [
          "network-online.target"
          "postgresql.service"
          "openldap.service"
        ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          Type = "simple";
          User = "stalwart";
          Group = "stalwart";
          Restart = "on-failure";
          RestartSec = 5;
          StateDirectory = "stalwart";
          CacheDirectory = "stalwart";
          LogsDirectory = "stalwart";
          EnvironmentFile = config.sops.templates."stalwart-recovery-admin.env".path;
          LoadCredential = [
            "ldap_replicator_password:${config.sops.secrets."openldap/replicatorPassword".path}"
          ];
          ExecStart = "${getExe package} --config=${configJson}";
          AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
          CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
        };
      };

      systemd.services.stalwart-bootstrap = {
        description = "Stalwart configuration bootstrap";
        after = [ "stalwart.service" ];
        wantedBy = [ "multi-user.target" ];
        startLimitIntervalSec = 120;
        startLimitBurst = 30;
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          Restart = "on-failure";
          RestartSec = 3;
          EnvironmentFile = config.sops.templates."stalwart-bootstrap.env".path;
          # stalwart.service is Type=simple with no systemd readiness
          # notification, so `after` only orders after the process is spawned.
          # Wait (bounded) for the management API: bootstrap/recovery mode
          # serves it on 8080 only, while every run with a configured store
          # serves the management listener and nothing on 8080.
          ExecStartPre = toString (pkgs.writeShellScript "stalwart-wait-api" ''
            for _ in $(seq 60); do
              for port in ${toString managementPort} 8080; do
                if ${pkgs.curl}/bin/curl --silent --output /dev/null --fail "http://127.0.0.1:$port/healthz/live"; then
                  exit 0
                fi
              done
              sleep 1
            done
            echo "stalwart management API did not become reachable" >&2
            exit 1
          '');
          ExecStart = toString (pkgs.writeShellScript "stalwart-apply" ''
            url=http://127.0.0.1:${toString managementPort}
            ${pkgs.curl}/bin/curl --silent --output /dev/null --fail "$url/healthz/live" || url=http://127.0.0.1:8080
            exec ${getExe pkgs.stalwart-cli} --url "$url" apply --file ${planFile}
          '');
          ExecStartPost = "${pkgs.systemd}/bin/systemctl restart stalwart.service";
        };
      };

      services.nginx.virtualHosts."mail-admin.${domain}" = {
        forceSSL = true;
        useACMEHost = domain;
        locations."/".proxyPass = "http://127.0.0.1:${toString managementPort}";
      };

      services.nginx.virtualHosts."${fqdn}" = {
        forceSSL = true;
        useACMEHost = domain;
        locations."/".proxyPass = "http://127.0.0.1:${toString managementPort}";
      };

      services.nginx.virtualHosts."${domain}".locations = {
        "/.well-known/jmap".proxyPass = "http://127.0.0.1:${toString managementPort}/.well-known/jmap";
        "/jmap/".proxyPass = "http://127.0.0.1:${toString managementPort}/jmap/";
      };
    };
}
