{ config, self, ... }:
let
  inherit (self.lib.ldap) getOlcSuffix;
  inherit (config.flake.public.config) legacy domain;
  inherit (config.flake.public.config.machines) dn-server;
  inherit (config.flake.public.config.services) mailserver stalwart;
in
{
  # Public MX/submission gateway: validates recipients against LDAP, relays
  # everything to dn-server for storage (see dn-server/services/stalwart.nix).
  # Hand-rolled unit since stalwart_0_16 is incompatible with the native
  # `services.stalwart` module.
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
      legacyDomain = legacy.domain;
      olcDomain = getOlcSuffix legacyDomain;
      certDir = config.security.acme.certs."${domain}".directory;

      getCredFile = var_name: "/run/credentials/stalwart.service/${var_name}";

      # Fresh RocksDb store - mail already migrated off dn-cc via imapsync,
      # nothing to preserve from the old 0.15.5 postgres-backed deployment.
      configJson = pkgs.writeText "stalwart-config.json" (
        builtins.toJSON {
          "@type" = "RocksDb";
          path = "/var/lib/stalwart/data";
        }
      );

      plan = [
        {
          # webadmin is a pluggable "Application" fetched at runtime; point
          # it at nixpkgs' prebuilt zip via file:// instead of a network
          # fetch. Access is restricted nginx-side, not here.
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
              # Stalwart generates/rotates the signing keys and (with
              # dnsManagement below) publishes/retires the DKIM TXT records
              # itself, no manual DkimSignature object needed.
              dkimManagement = {
                "@type" = "Automatic";
                algorithms = {
                  Dkim1RsaSha256 = true;
                  Dkim1Ed25519Sha256 = true;
                };
              };
              # Only DKIM/SPF/DMARC - Mx/AutoConfig/AutoDiscover are
              # hand-managed elsewhere.
              dnsManagement = {
                "@type" = "Automatic";
                dnsServerId = "#cloudflare-dns";
                publishRecords = {
                  dkim = true;
                  spf = true;
                  dmarc = true;
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
          # LdapDirectory has no stable upsert key - matches on nothing,
          # first apply always creates.
          value = {
            # Local read-only openldap replica (openldap.nix), bound as the
            # syncrepl replicator identity - already has read access to
            # userPassword. Used only to validate recipients/authenticate
            # senders; delivery always goes to dn-server (MtaOutboundStrategy).
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
              # The *.dnywe.com cert is never valid for a bare IP - hop
              # stays inside WireGuard anyway.
              allowInvalidCerts = true;
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
          "@type" = "update";
          object = "Authentication";
          value = {
            directoryId = "#dir-ldap";
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
          };
        }
        {
          # "disable" is a recognized expression constant -> AggregateFrequency::Never.
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
          # Auto-ban rules, off by default - relevant here since smtp:25 and
          # submission(s) are open to the whole internet.
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
          value.scoreSpam = 8;
        }
        # Unwanted default bootstrap listeners (dn-cc has no local mailboxes;
        # https:443 conflicts with nginx). Bound dual-stack ([::]), which
        # was the source of the "IPv6 unavailable" warnings.
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
          Environment = "STALWART_URL=http://127.0.0.1:8080";
          ExecStart = "${getExe pkgs.stalwart-cli} apply --file ${planFile}";
          ExecStartPost = "${pkgs.systemd}/bin/systemctl restart stalwart.service";
        };
      };
    };
}
