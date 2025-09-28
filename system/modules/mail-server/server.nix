{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.mail-server;
  dcList = strings.splitString "." cfg.domain;
  ldapDomain = strings.concatStringsSep "," (lists.forEach dcList (dc: "dc=" + dc));

  dovecotSecretPath = "/run/dovecot-secret";
  authBaseConf = pkgs.writeText "dovecot-auth.conf.ext" ''
    passdb ldap {
      auth_username_format = %{user | lower}
      ldap_bind = no
      ldap_filter = (&(objectClass=inetOrgPerson)(uid=%{user | username}))
      use_worker = no

      fields {
        user = %{ldap:mail}
        password = %{ldap:userPassword}
      }
    }
    ldap_auth_dn = cn=admin,${ldapDomain}
    ldap_auth_dn_password = $LDAP_PASSWORD
    ldap_uris = ldap://localhost
    ldap_base = ${ldapDomain}
  '';
  authConf = "${dovecotSecretPath}/dovecot-auth.conf.ext";

  dovecotDomain = config.services.postfix.settings.main.myhostname;
in
{
  config = mkIf cfg.enable {
    security.acme.certs = mkIf cfg.configureACME {
      "${config.services.postfix.settings.main.myhostname}" = {
        dnsProvider = null;
        webroot = "/var/lib/acme/acme-challenge";
        postRun = ''
          systemctl restart postfix.service
          systemctl restart dovecot.service
        '';
      };
      "${cfg.domain}" = {
        dnsProvider = null;
        webroot = "/var/lib/acme/acme-challenge";
      };
    };

    # ===== opendkim ===== #
    services.opendkim = {
      enable = true;
      domains = "csl:${cfg.domain}";
      selector = "mail";
    };

    # ===== Postfix ===== #
    environment.sessionVariables = {
      MAILDIR = cfg.mailDir;
    };

    systemd.services.postfix = {
      requires = [
        "acme-finished-${config.services.postfix.settings.main.myhostname}.target"
      ];
      serviceConfig.LoadCredential =
        let
          certDir =
            config.security.acme.certs."${config.services.postfix.settings.main.myhostname}".directory;
        in
        [
          "cert.pem:${certDir}/cert.pem"
          "key.pem:${certDir}/key.pem"
        ];
    };

    services.postfix = {
      enable = true;
      virtual = cfg.virtual;
      enableSubmissions = true;

      settings.main =
        let
          credsDir = "/run/credentials/postfix.service";
          certDir = "${credsDir}/cert.pem";
          keyDir = "${credsDir}/key.pem";
        in
        {
          myhostname = "mail.${cfg.domain}";
          mynetworks = cfg.networks;
          mydestination = cfg.destination;
          myorigin = if cfg.origin == "" then cfg.domain else cfg.origin;
          relayhost = [ "0.0.0.0:465" ];
          smtpd_tls_security_level = "encrypt";
          smtpd_client_restrictions = "permit_mynetworks, permit_sasl_authenticated, reject";
          smtpd_relay_restrictions = "permit_mynetworks, permit_sasl_authenticated, reject_unauth_destination";
          milter_macro_daemon_name = "ORIGINATING";

          virtual_uid_maps = [
            "static:${toString cfg.uid}"
          ];
          virtual_gid_maps = [
            "static:${toString cfg.gid}"
          ];

          virtual_mailbox_domains = [ cfg.domain ];
          virtual_transport = "lmtp:unix:private/dovecot-lmtp";
          smtpd_sasl_type = "dovecot";
          smtpd_sasl_path = "private/auth";
          smtpd_sasl_auth_enable = "yes";
          tls_random_source = "dev:/dev/urandom";

          smtp_tls_security_level = "may";
          smtp_tls_chain_files = [
            keyDir
            certDir
          ];

          smtpd_tls_chain_files = [
            keyDir
            certDir
          ];

          home_mailbox = cfg.mailDir;
        }
        // optionalAttrs config.services.opendkim.enable (
          let
            opendkimSocket = strings.removePrefix "local:" config.services.opendkim.socket;
          in
          {
            smtpd_milters = [ "unix:${opendkimSocket}" ];
            non_smtpd_milters = [ "unix:${opendkimSocket}" ];
            milter_default_action = "accept";
          }
        );

      rootAlias = cfg.rootAlias;
      postmasterAlias = "root";
      extraAliases = ''
        mailer-daemon: postmaster
        nobody: root
        hostmaster: root
        usenet: root
        news: root
        webmaster: root
        www: root
        ftp: root
        abuse: root
        noc: root
        security: root
      ''
      + cfg.extraAliases;
    };

    services.rspamd = {
      enable = true;
      postfix.enable = true;
      workers = {
        normal = {
          includes = [ "$CONFDIR/worker-normal.inc" ];
          bindSockets = [
            {
              socket = "/run/rspamd/rspamd.sock";
              mode = "0660";
              owner = "${config.services.rspamd.user}";
              group = "${config.services.rspamd.group}";
            }
          ];
        };
        controller = {
          includes = [ "$CONFDIR/worker-controller.inc" ];
          bindSockets = [ "127.0.0.1:${toString cfg.rspamd.port}" ];
          extraConfig = ''
            password=$2$w3asngzxwp3hoa67gimtrgmdxzmpq1n1$knfe5cyb1f769zro4rsi3j8ipc1p7ewh3u4cz63ngidmpjs8955y
          '';
        };
      };
    };

    # ===== rspamd trainer ===== #
    services.rspamd-trainer = {
      enable = true;
      settings = {
        HOST = dovecotDomain;
        USERNAME = "spam@${cfg.domain}";
        INBOXPREFIX = "INBOX.";
      };
      secrets = [
        cfg.rspamd.trainerSecret
      ];
    };

    systemd.services.rspamd-trainer = lib.mkIf config.services.rspamd-trainer.enable {
      after = [
        "postfix.service"
        "dovecot.service"
        "rspamd-trainer-pre.service"
      ];
      requires = [ "rspamd-trainer-pre.service" ];
    };

    # ===== Create Mailbox for rspamd trainer ===== #
    systemd.services.rspamd-trainer-pre = lib.mkIf config.services.rspamd-trainer.enable {
      serviceConfig = {
        ExecStart =
          let
            script = pkgs.writeShellScript "rspamd-trainer-pre.sh" ''
              set -euo pipefail

              username=${config.services.rspamd-trainer.settings.USERNAME}
              domain="${cfg.domain}"
              mailbox_list=("report_spam" "report_ham" "report_spam_reply")
              for mailbox in ''\${mailbox_list[@]}; do
                echo "Creating $mailbox..."
                ${pkgs.dovecot}/bin/doveadm mailbox create -u "$username@$domain" "INBOX.$mailbox" 2>/dev/null || true
              done
            '';
          in
          "${pkgs.bash}/bin/bash ${script}";
        Type = "oneshot";
      };
    };

    # ===== Dovecot ===== #
    systemd.services.dovecot = {
      requires = [ "acme-finished-${dovecotDomain}.target" ];
      serviceConfig = {
        RuntimeDirectory = [ "dovecot-secret" ];
        RuntimeDirectoryMode = "0640";
        ExecStartPre = [
          ''${pkgs.busybox.out}/bin/mkdir -p ${cfg.virtualMailDir}''
          ''${pkgs.busybox.out}/bin/chown -R vmail:vmail ${cfg.virtualMailDir}''
          ''${pkgs.busybox.out}/bin/chmod 770 ${cfg.virtualMailDir}''
          ''${pkgs.bash}/bin/bash -c "LDAP_PASSWORD=$(cat ${cfg.ldap.passwordFile}) ${pkgs.gettext.out}/bin/envsubst < ${authBaseConf} > ${authConf}"''
          ''${pkgs.busybox.out}/bin/chown ${config.services.dovecot.user}:${config.services.dovecot.group} ${authConf}''
          ''${pkgs.busybox.out}/bin/chmod 660 ${authConf}''
        ];

        LoadCredential =
          let
            certDir = config.security.acme.certs."${dovecotDomain}".directory;
          in
          [
            "cert.pem:${certDir}/cert.pem"
            "key.pem:${certDir}/key.pem"
          ];
      };
    };

    services.dovecot =
      let
        credsDir = "/run/credentials/dovecot.service";
        certDir = "${credsDir}/cert.pem";
        keyDir = "${credsDir}/key.pem";
      in
      {
        enable = true;
        enablePAM = false;
        enableImap = true;
        enablePop3 = true;
        enableLmtp = true;
        enableHealthCheck = true;
        mailLocation = lib.mkDefault "${cfg.mailDir}";
        mailUser = "vmail";
        mailGroup = "vmail";
        sslServerKey = keyDir;
        sslServerCert = certDir;

        mailboxes = {
          Junk = {
            specialUse = "Junk";
            auto = "subscribe";
          };
          Drafts = {
            specialUse = "Drafts";
            auto = "subscribe";
          };
          Archive = {
            specialUse = "Archive";
            auto = "subscribe";
          };
          Sent = {
            specialUse = "Sent";
            auto = "subscribe";
          };
        };

        extraConfig = ''
          # authentication debug logging
          log_path = /dev/stderr
          log_debug = (category=auth-client) OR (event=auth_client_passdb_lookup_started)

          auth_mechanisms = plain login
          ssl = required

          service auth {
            unix_listener ${config.services.postfix.settings.main.queue_directory}/private/auth {
              mode = 0660
              user = ${config.services.postfix.user}
              group = ${config.services.postfix.group}
              type = postfix
            }
          }

          service lmtp {
            unix_listener ${config.services.postfix.settings.main.queue_directory}/private/dovecot-lmtp {
              mode = 0660
              user = ${config.services.postfix.user}
              group = ${config.services.postfix.group}
              type = postfix
            }
          }

          userdb static {
            fields {
              uid = ${toString cfg.uid}
              gid = ${toString cfg.gid}
              home = ${cfg.virtualMailDir}/%{user | domain}/%{user | username}
            }
          }

          lda_mailbox_autosubscribe = yes
          lda_mailbox_autocreate = yes

          !include ${authConf}
        '';
      };

    systemd.services.dovecot-healthcheck = mkIf config.services.dovecot.enableHealthCheck (
      let
        pythonServer =
          pkgs.writeScript "dovecot-healthcheck"
            # python
            ''
              #!${pkgs.python3}/bin/python3
              import socket
              from http.server import BaseHTTPRequestHandler, HTTPServer

              DOVECOT_HOST = '127.0.0.1'
              DOVECOT_PORT = ${toString config.services.dovecot.healthCheckPort}

              class HealthCheckHandler(BaseHTTPRequestHandler):
                  def do_GET(self):
                      if self.path != '/ping':
                          self.send_response(404)
                          self.end_headers()
                          return
                      try:
                          with socket.create_connection((DOVECOT_HOST, DOVECOT_PORT), timeout=5) as sock:
                              sock.sendall(b"PING\n")
                              data = sock.recv(1024).strip()
                      except Exception as e:
                          self.send_response(500)
                          self.end_headers()
                          self.wfile.write(b"Error connecting to healthcheck service")
                          return

                      if data == b"PONG":
                          self.send_response(200)
                          self.send_header("Content-Type", "text/plain")
                          self.end_headers()
                          self.wfile.write(b"PONG")
                      else:
                          self.send_response(500)
                          self.end_headers()
                          self.wfile.write(b"Unexpected response")

              if __name__ == '__main__':
                  server = HTTPServer(('0.0.0.0', 5002), HealthCheckHandler)
                  print("HTTP healthcheck proxy running on port 5002")
                  server.serve_forever()
            '';
      in
      {
        requires = [ "dovecot.service" ];
        wantedBy = [ "multi-user.target" ];
        after = [ "dovecot.service" ];
        serviceConfig = {
          Type = "simple";
          ExecStart = pythonServer;
        };
      }
    );

    # ===== Firewall ===== #
    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [
      80 # HTTP
      443 # HTTPS
      25 # SMTP
      465 # SMTPS
      587 # STARTTLS
      143 # IMAP STARTTLS
      993 # IMAPS
      110 # POP3 STARTTLS
      995 # POP3S
      389 # LDAP
    ];

    services.postgresql = {
      enable = true;
      ensureDatabases = [ "keycloak" ];
      ensureUsers = [
        {
          name = "keycloak";
          ensureDBOwnership = true;
        }
      ];
    };

    # ===== OAuth keycloak ===== #
    services.keycloak = {
      enable = true;

      database = {
        type = "postgresql";
        host = "localhost";
        name = "keycloak";
        createLocally = false;
        passwordFile = cfg.oauth.passwordFile;
      };

      settings = {
        hostname = "keycloak.${cfg.domain}";
        proxy-headers = "xforwarded";
        http-port = 38080;
        http-enabled = true;
        health-enabled = true;
        http-management-port = 38081;
        truststore-paths = cfg.caFile;
      };
    };

    # ==== LDAP ===== #
    services.openldap = {
      enable = true;

      urlList = [ "ldap:///" ];
      settings = {
        attrs = {
          olcLogLevel = "conns config";
        };

        children = {
          "cn=schema".includes = [
            "${pkgs.openldap}/etc/schema/core.ldif"
            "${pkgs.openldap}/etc/schema/cosine.ldif"
            "${pkgs.openldap}/etc/schema/inetorgperson.ldif"
          ];

          "olcDatabase={1}mdb" = {
            attrs = {
              objectClass = [
                "olcDatabaseConfig"
                "olcMdbConfig"
              ];

              olcDatabase = "{1}mdb";
              olcDbDirectory = "/var/lib/openldap/data";

              olcSuffix = ldapDomain;

              olcRootDN = "cn=admin,${ldapDomain}";
              olcRootPW.path = cfg.ldap.passwordFile;

              olcAccess = [
                ''
                  {0}to attrs=userPassword
                      by dn.exact="cn=admin,${ldapDomain}" read
                      by dn.exact="uid=admin@${cfg.domain},ou=people,${ldapDomain}" write
                      by self write
                      by anonymous auth
                      by * none
                ''
                ''
                  {1}to *
                      by dn.exact="uid=admin@${cfg.domain},ou=people,${ldapDomain}" write
                      by * read
                ''
              ];
            };

            children = {
              "olcOverlay={2}ppolicy".attrs = {
                objectClass = [
                  "olcOverlayConfig"
                  "olcPPolicyConfig"
                  "top"
                ];
                olcOverlay = "{2}ppolicy";
                olcPPolicyHashCleartext = "TRUE";
              };

              "olcOverlay={3}memberof".attrs = {
                objectClass = [
                  "olcOverlayConfig"
                  "olcMemberOf"
                  "top"
                ];
                olcOverlay = "{3}memberof";
                olcMemberOfRefInt = "TRUE";
                olcMemberOfDangling = "ignore";
                olcMemberOfGroupOC = "groupOfNames";
                olcMemberOfMemberAD = "member";
                olcMemberOfMemberOfAD = "memberOf";
              };

              "olcOverlay={4}refint".attrs = {
                objectClass = [
                  "olcOverlayConfig"
                  "olcRefintConfig"
                  "top"
                ];
                olcOverlay = "{4}refint";
                olcRefintAttribute = "memberof member manager owner";
              };
            };
          };
        };
      };
    };

    # ==== postsrsd ==== #
    services.postsrsd = {
      enable = true;
      configurePostfix = true;
      secretsFile = config.sops.secrets."postsrsd/secret".path;
      settings = {
        srs-domain = cfg.domain;
        domains = [ cfg.domain ];
      };
    };

    virtualisation = {
      docker = {
        enable = true;
        rootless = {
          enable = true;
          setSocketVariable = true;
        };
      };
      oci-containers = {
        backend = "podman";
        containers = {
          phpLDAPadmin = {
            extraOptions = [ "--network=host" ];
            image = "phpldapadmin/phpldapadmin";
            volumes = [
              "/var/lib/pla/logs:/app/storage/logs"
              "/var/lib/pla/sessions:/app/storage/framework/sessions"
            ];
            environment = {
              APP_URL = "https://ldap.${cfg.domain}";
              ASSET_URL = "https://ldap.${cfg.domain}";
              APP_TIMEZONE = "Asia/Taipei";
              LDAP_HOST = "127.0.0.1";
              SERVER_NAME = ":8080";
              LDAP_LOGIN_OBJECTCLASS = "inetOrgPerson";
              LDAP_BASE_DN = "${ldapDomain}";
              LDAP_LOGIN_ATTR = "dn";
              LDAP_LOGIN_ATTR_DESC = "Username";
            };
            environmentFiles = [
              cfg.ldap.webEnv
            ];
          };
        };
      };
    };

    # ===== Virtual Mail User ===== #
    users.groups.vmail = {
      gid = cfg.gid;
    };

    users.users.vmail = {
      uid = cfg.uid;
      group = "vmail";
    };

    services.nginx = {
      enable = mkDefault true;
      recommendedGzipSettings = mkDefault true;
      recommendedOptimisation = mkDefault true;
      recommendedTlsSettings = mkDefault true;
      recommendedProxySettings = mkDefault true;

      virtualHosts = {
        "${config.services.postfix.settings.main.myhostname}" = {
          enableACME = true;
          forceSSL = true;
          locations."/dovecot/ping".proxyPass = "http://localhost:${toString 5002}/ping";
        };
        "ldap.${cfg.domain}" = {
          enableACME = true;
          forceSSL = true;
          locations."/".proxyPass = "http://localhost:${toString 8080}/";
        };
        "rspamd.${cfg.domain}" = mkIf config.services.rspamd.enable {
          enableACME = true;
          forceSSL = true;
          locations."/".proxyPass = "http://localhost:${toString cfg.rspamd.port}/";
        };
        "${config.services.keycloak.settings.hostname}" = mkIf config.services.keycloak.enable {
          enableACME = true;
          forceSSL = true;
          locations."/".proxyPass =
            "http://localhost:${toString config.services.keycloak.settings.http-port}";
          locations."/health".proxyPass =
            "http://localhost:${toString config.services.keycloak.settings.http-management-port}/health";
        };
      };
    };
  };
}
