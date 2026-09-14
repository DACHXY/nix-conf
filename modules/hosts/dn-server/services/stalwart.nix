{ config, ... }:
let
  inherit (config.flake.public.config) domain;
  inherit (config.flake.public.config.services.openldap) olcDomain;
  inherit (config.flake.public.config.machines) dn-cc;
in
{
  # Backend mail store: dn-cc (hosts/dn-cc/services/stalwart.nix) is the
  # sole public MX/relay and relays here over WireGuard. Hand-rolled unit
  # since stalwart_0_16 is incompatible with the native `services.stalwart`
  # module.
  configurations.nixos.dn-server.module =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib) getExe concatMapStringsSep;

      package = pkgs.stalwart_0_16;
      dbName = "stalwart";
      # SystemSettings.defaultHostname: embedded as the apiUrl/downloadUrl/
      # etc. host in every JMAP session resource, so must be the publicly
      # reachable hostname the browser talks to (bulwark.nix), not internal.
      fqdn = "jmap.${domain}";
      managementPort = 30093;
      certDir = config.security.acme.certs."${domain}".directory;

      getCredFile = var_name: "/run/credentials/stalwart.service/${var_name}";

      # Bootstrap config: bare DataStore value telling stalwart where its
      # own registry lives. Everything else is configured via `plan` below.
      configJson = pkgs.writeText "stalwart-config.json" (
        builtins.toJSON {
          "@type" = "PostgreSql";
          host = "127.0.0.1";
          port = 5432;
          database = dbName;
          authUsername = dbName;
          poolMaxConnections = 10;
        }
      );

      # Declarative server-config plan, applied via stalwart-bootstrap below.
      plan = [
        # Objects referenced (by "#id") further down must be created first -
        # stalwart-cli applies in file order, doesn't defer references.
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
          # LdapDirectory has no "name" field to match on - description is
          # the closest thing it has.
          value = {
            # This host's own openldap master (openldap.nix), bound as the
            # same replicator identity dn-cc's replica uses.
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
          "@type" = "update";
          object = "Authentication";
          value = {
            directoryId = "#dir-ldap";
          };
        }
        {
          "@type" = "upsert";
          object = "MtaRoute";
          matchOn = [ "name" ];
          value = {
            # dn-server has no public IP/reputation of its own - all
            # outbound goes through dn-cc.
            relay-dncc = {
              name = "relay-dncc";
              "@type" = "Relay";
              address = dn-cc.ip;
              port = 25;
              protocol = "smtp";
              implicitTls = false;
              # The *.dnywe.com cert is never valid for a bare IP.
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
          # dn-cc already filters before relaying here.
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
          "@type" = "upsert";
          object = "NetworkListener";
          matchOn = [ "name" ];
          value = {
            smtp = {
              name = "smtp";
              protocol = "smtp";
              # NetworkListener.bind is a Map, not a list.
              bind."0.0.0.0:25" = true;
            };
            imap = {
              name = "imap";
              protocol = "imap";
              # Plain IMAP, no TLS - only reachable over WireGuard. Needed
              # as an imapsync destination migrating mailboxes from dn-cc.
              bind."0.0.0.0:143" = true;
            };
            imaps = {
              name = "imaps";
              protocol = "imap";
              bind."0.0.0.0:993" = true;
              useTls = true;
              tlsImplicit = true;
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

      # With a real (non-ephemeral) registry store there's no auto-generated
      # bootstrap password, so this fallback admin must be pinned for the
      # initial plan apply to authenticate at all.
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
        143 # IMAP, for imapsync migration from dn-cc over WireGuard
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
          # Default tracer writes here; directory never existed otherwise.
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
        # Not `requires`: ExecStartPost restarts stalwart.service, and
        # `requires` would propagate that stop back to this unit,
        # SIGTERM-ing itself mid-run.
        after = [ "stalwart.service" ];
        wantedBy = [ "multi-user.target" ];
        # `after` only waits for the process to fork, not for it to finish
        # connecting to postgres and bind its HTTP listener - retry until ready.
        startLimitIntervalSec = 120;
        startLimitBurst = 30;
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          Restart = "on-failure";
          RestartSec = 3;
          EnvironmentFile = config.sops.templates."stalwart-bootstrap.env".path;
          # Brand-new/empty registry -> stalwart's fixed bootstrap-mode port,
          # before `plan` creates the real "management" listener.
          Environment = "STALWART_URL=http://127.0.0.1:8080";
          ExecStart = "${getExe pkgs.stalwart-cli} apply --file ${planFile}";
          # New/changed listeners only take effect on restart.
          ExecStartPost = "${pkgs.systemd}/bin/systemctl restart stalwart.service";
        };
      };

      services.nginx.virtualHosts."mail-admin.${domain}" = {
        forceSSL = true;
        useACMEHost = domain;
        locations."/".proxyPass = "http://127.0.0.1:${toString managementPort}";
      };
    };
}
