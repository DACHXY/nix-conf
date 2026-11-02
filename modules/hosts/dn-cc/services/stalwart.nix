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

      package = pkgs.stalwart_1_0;
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
          path = "/var/lib/stalwart-v1/data";
        }
      );

      plan = [
        {
          "@type" = "upsert";
          object = "Application";
          value = {
            webadmin = {
              enable = true;
              description = "webadmin";
              # 1.0 only loads a major-version-2 WebUI bundle. It fetches the bundle
              # over http(s) only (`file://` is silently ignored -> every app path 404s),
              # so pin the upstream v2 tag here instead of the local zip.
              resourceUrl = "https://github.com/stalwartlabs/webui/releases/download/v2.0.0/webui.zip";
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
              filterRecipient = "(|(mail=?)(mailRoutingAddress=?))";
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
              host = dn-server.ip;
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
          object = "OidcProvider";
          value = {
            # OAuth issuer: Stalwart advertises https://mx2.<domain> (fqdn
            # above) in its discovery document, so third-party clients end up
            # talking to that host -- see the mx2 vhost in nginx.nix.
            #
            # Stalwart rejects OAuth clients whose client_id is an HTTPS
            # metadata document by default. Such clients are shown
            # as unverified on the consent screen, which is the upstream
            # tradeoff for trusting the document.
            clientMetadataDocuments = "any";
          };
        }
        {
          "@type" = "update";
          object = "MtaStageData";
          # No DATA-stage Sieve script (the schema default is `false`). Pinned
          # explicitly so a script name applied earlier is cleared instead of
          # lingering in the store, where `update` would leave it untouched.
          value.script = {
            # Expression fields serialize as a condition map plus a default;
            # a constant is just the default.
            "else" = "false";
          };
          value.dkimSignDomain = {
            match."0" = {
              # Two ways a local-domain message can reach the public listener:
              # a submission authenticated as the user, or a relay from the
              # mailbox backend (dn-server) over WireGuard -- that hop is
              # unauthenticated, and without it this mail left unsigned, which
              # costs the domain DMARC alignment at the recipient.
              "if" =
                "is_local_domain(sender_domain) && (!is_empty(authenticated_as) || remote_ip == '${dn-server.ip}')";
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
          matchOn = [ "url" ];
          value = {
            tracer-history = {
              "@type" = "OtelHttp";
              url = "http://127.0.0.1:${toString stalwart.otlpPort}/v1/logs";
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
                # Without the failures below a per-account view can say a
                # message left the queue but never why it died. Each of these
                # carries `from` (return path) and `to` (recipient), which is
                # what the account dashboard filters on:
                #   failed            temporary error, retry scheduled
                #   dsn-temp/perm-fail the bounce that was (or will be) sent
                #   rcpt-to-*         remote server refused one recipient
                #   the rest          attempt died before SMTP even started
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
          # Spans for the Grafana traces view / Traces Drilldown (Tempo on
          # dn-server). Spans use the endpoint verbatim (the OTLP exporter
          # only appends /v1/traces when no path is given), so traces and
          # logs need separate tracers: this one logs nothing.
          "@type" = "upsert";
          object = "Tracer";
          matchOn = [ "url" ];
          value = {
            tracer-spans = {
              "@type" = "OtelHttp";
              url = "http://127.0.0.1:${toString stalwart.otlpPort}/v1/traces";
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
          "@type" = "update";
          object = "SpamSettings";
          value.scoreSpam = 8;
        }
        {
          # dn-server is the mailbox backend and has no internet route of its
          # own: every outbound message there is routed to this host over
          # WireGuard. The RCPT stage's default policy only relays for
          # authenticated sessions (`!is_empty(authenticated_as)`), so those
          # hand-offs were refused with `smtp.relay-not-allowed` -- external
          # mail from dn-server never left the queue.
          #
          # Trust the tunnel peer addresses rather than switching on
          # Domain.allowRelaying: that flag is applied unconditionally in
          # rcpt_resolve (no auth check at all), which would turn this public
          # gateway into an open relay. Matching remote_ip keeps the trust to
          # the two WireGuard addresses dn-server can appear as.
          "@type" = "update";
          object = "MtaStageRcpt";
          value.allowRelaying = {
            match = {
              "0" = {
                "if" = "!is_empty(authenticated_as)";
                "then" = "true";
              };
              "1" = {
                "if" = "remote_ip == '${dn-server.ip}'";
                "then" = "true";
              };
              "2" = {
                "if" = "remote_ip == '${dn-server.wg.wg0.ip}'";
                "then" = "true";
              };
            };
            "else" = "false";
          };
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
              implicitTls = true;
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
          StateDirectory = "stalwart-v1";
          CacheDirectory = "stalwart-v1";
          # Default tracer writes here; directory never existed otherwise.
          LogsDirectory = "stalwart-v1";
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
          # stalwart.service is Type=simple with no systemd readiness
          # notification, so `after` only orders after the process is spawned.
          # Wait (bounded) for the management API: bootstrap/recovery mode
          # serves it on 8080 only, the configured management listener covers
          # every run after the plan has been applied once.
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
    };
}
