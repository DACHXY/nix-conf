{ config, self, ... }:
let
  inherit (self.lib.ldap) getOlcSuffix;
  inherit (config.flake.public.config) legacy domain;
  inherit (config.flake.public.config.machines) dn-server dn-cc;
  inherit (config.flake.public.config.services) mailserver stalwart;
in
{
  configurations.nixos.dn-cc.module =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib) getExe concatMapStringsSep;

      package = pkgs.stalwart_0_16;
      fqdn = mailserver.hostname;
      managementPort = stalwart.managementPort;
      metricsPort = stalwart.metricsPort;
      legacyDomain = legacy.domain;
      olcDomain = getOlcSuffix legacyDomain;
      certDir = config.security.acme.certs."${domain}".directory;

      getCredFile = var_name: "/run/credentials/stalwart.service/${var_name}";

      configJson = pkgs.writeText "stalwart-config.json" (
        builtins.toJSON {
          "@type" = "RocksDb";
          path = "/var/lib/stalwart/data";
        }
      );

      plan = [
        {
          "@type" = "upsert";
          object = "Application";
          value = {
            webadmin = {
              enabled = true;
              description = "webadmin";
              resourceUrl = "file://${package.webui}/webui.zip";
              urlPrefix."/account" = true;
            };
          };
        }
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
              # Matches the ACME cert's SANs (users/danny/acme.nix).
              subjectAlternativeNames = {
                "${domain}" = true;
                "*.${domain}" = true;
              };
            };
          };
        }
        {
          # Zone:DNS:Edit-scoped token, separate from ACME/lego's DNS-01 one.
          "@type" = "upsert";
          object = "DnsServer";
          matchOn = [ "description" ];
          value = {
            cloudflare-dns = {
              description = "cloudflare";
              "@type" = "Cloudflare";
              secret = {
                "@type" = "File";
                filePath = getCredFile "cloudflare_dns_token";
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
                "@type" = "Automatic";
                algorithms = {
                  Dkim1RsaSha256 = true;
                  Dkim1Ed25519Sha256 = true;
                };
              };
              dnsManagement = {
                "@type" = "Automatic";
                dnsServerId = "#cloudflare-dns";
                publishRecords = {
                  dkim = true;
                  spf = true;
                  dmarc = true;
                  mtaSts = true;
                  tlsRpt = true;
                };
              };
              subAddressing = {
                "@type" = "Disabled";
              };
            };
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
              filterMailbox = "(|(mail=?)(mailRoutingAddress=?))";
              attrEmail.mail = true;
              attrSecret.userPassword = true;
            };
          };
        }
        {
          "@type" = "upsert";
          object = "MtaRoute";
          matchOn = [ "name" ];
          value = {
            relay-dnserver = {
              name = "relay-dnserver";
              "@type" = "Relay";
              address = dn-server.ip;
              port = 25;
              protocol = "smtp";
              implicitTls = false;
              allowInvalidCerts = true;
            };
          };
        }
        {
          "@type" = "upsert";
          object = "MtaTlsStrategy";
          matchOn = [ "name" ];
          value = {
            no-dane = {
              name = "no-dane";
              dane = "disable";
            };
          };
        }
        {
          "@type" = "update";
          object = "MtaSts";
          value = {
            mode = "enforce";
            maxAge = 604800000;
            mxHosts.${fqdn} = true;
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
          "@type" = "update";
          object = "Authentication";
          value = {
            directoryId = "#dir-ldap";
          };
        }
        {
          "@type" = "update";
          object = "SenderAuth";
          value.dkimSignDomain = {
            match."0" = {
              "if" = "is_local_domain(sender_domain) && !is_empty(authenticated_as)";
              "then" = "sender_domain";
            };
            "else" = "false";
          };
        }
        {
          "@type" = "update";
          object = "MtaOutboundStrategy";
          value = {
            # Route names are the MtaRoute's own "name" field, not "#id".
            route = {
              # List<T> serializes as a JSON object keyed by stringified
              # index ("0", "1", ...), not an array.
              match."0" = {
                "if" = "rcpt_domain == '${domain}'";
                "then" = "'relay-dnserver'";
              };
              "else" = "'mx'";
            };
            # See MtaTlsStrategy "no-dane" above.
            tls."else" = "'no-dane'";
          };
        }
        {
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
          object = "Metrics";
          value = {
            # Exposes GET /metrics/prometheus on every `http` listener.
            # Only the `metrics` listener below is reachable from dn-server.
            # No authUsername/authSecret: the WireGuard link plus an
            # interface-scoped firewall rule are the access control.
            prometheus = {
              "@type" = "Enabled";
            };
          };
        }
        {
          # Per-message history for the Grafana "Stalwart history" dashboard.
          # Pushed as OTLP logs to the local Alloy agent (services/alloy.nix),
          # which copies the OTLP EventName into an attribute (Loki's OTLP
          # ingest drops EventName) and forwards to Loki on dn-server.
          "@type" = "upsert";
          object = "Tracer";
          matchOn = [ "endpoint" ];
          value = {
            tracer-history = {
              "@type" = "OtelHttp";
              endpoint = "http://127.0.0.1:${toString stalwart.otlpPort}/v1/logs";
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
                "delivery.dsn-perm-fail"
                "security.authentication-ban"
                "security.abuse-ban"
                "security.scan-ban"
                "security.ip-blocked"
              ] (_: true);
            };
          };
        }
        {
          "@type" = "update";
          object = "SpamSettings";
          value.scoreSpam = 8;
        }
        {
          # Stalwart's telemetry never carries the Subject header, so the
          # message history in Grafana gets it from here: the DATA-stage hook hands
          # the envelope and headers to the local receiver in
          # services/stalwart-mta-hook.nix, which forwards them to Loki.
          # tempFailOnError = false keeps a dead receiver from refusing mail.
          "@type" = "upsert";
          object = "MtaHook";
          matchOn = [ "url" ];
          value.hook-history = {
            url = "http://127.0.0.1:${toString stalwart.mtaHookPort}/mta-hook";
            tempFailOnError = false;
          };
        }
      ]
      ++ (map
        (name: {
          "@type" = "destroy";
          object = "NetworkListener";
          value.name = name;
        })
        [
          "http"
          "https"
          "sieve"
          "pop3s"
          "imaps"
        ]
      )
      ++ [
        {
          "@type" = "upsert";
          object = "NetworkListener";
          matchOn = [ "name" ];
          value = {
            smtp = {
              name = "smtp";
              protocol = "smtp";
              bind."0.0.0.0:25" = true;
              useTls = true;
            };
            submission = {
              name = "submission";
              protocol = "smtp";
              bind."0.0.0.0:587" = true;
              useTls = true;
            };
            submissions = {
              name = "submissions";
              protocol = "smtp";
              bind."0.0.0.0:465" = true;
              useTls = true;
              tlsImplicit = true;
            };
            management = {
              name = "management";
              protocol = "http";
              bind."127.0.0.1:${toString managementPort}" = true;
              useTls = false;
            };
            metrics = {
              name = "metrics";
              protocol = "http";
              # Bound on all interfaces; the firewall only opens this port on
              # the WireGuard interface so dn-server can scrape it.
              bind."0.0.0.0:${toString metricsPort}" = true;
              useTls = false;
            };
          };
        }
      ];

      planText = concatMapStringsSep "\n" (op: builtins.toJSON op) plan;
      planFile = pkgs.writeText "stalwart-plan.ndjson" planText;
    in
    {
      sops.secrets."stalwart/adminPassword" = {
        owner = "stalwart";
        group = "stalwart";
        mode = "640";
      };

      sops.secrets."cloudflare/stalwartDnsToken" = {
        owner = "stalwart";
        group = "stalwart";
        mode = "400";
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
        25
        587
        465
      ];

      # /metrics/prometheus is served on every Stalwart `http` listener, so the
      # metrics port is reachable from any WireGuard peer of this interface
      # (only dn-server). Everything else stays default-dropped.
      networking.firewall.interfaces.${dn-cc.wg.wg0.interface}.allowedTCPPorts = [
        metricsPort
      ];

      systemd.services.stalwart = {
        description = "Stalwart Mail Server (public relay/gateway)";
        wantedBy = [ "multi-user.target" ];
        after = [
          "network-online.target"
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
          # Default tracer writes here; directory never existed otherwise.
          LogsDirectory = "stalwart";
          EnvironmentFile = config.sops.templates."stalwart-recovery-admin.env".path;
          LoadCredential = [
            "ldap_replicator_password:${config.sops.secrets."openldap/replicatorPassword".path}"
            "cloudflare_dns_token:${config.sops.secrets."cloudflare/stalwartDnsToken".path}"
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
          Environment = "STALWART_URL=http://127.0.0.1:${toString managementPort}";
          # stalwart.service is Type=simple with no systemd readiness
          # notification, so `after` only orders after the process is spawned.
          # Wait (bounded) for the management listener before applying.
          ExecStartPre = "${pkgs.curl}/bin/curl --silent --show-error --output /dev/null --connect-timeout 5 --retry 30 --retry-delay 1 --retry-connrefused http://127.0.0.1:${toString managementPort}/api/schema";
          ExecStart = "${getExe pkgs.stalwart-cli} apply --file ${planFile}";
          ExecStartPost = "${pkgs.systemd}/bin/systemctl restart stalwart.service";
        };
      };
    };
}
