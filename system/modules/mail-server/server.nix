{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.mail-server;

  dcList = lib.strings.splitString "." cfg.domain;
  ldapDomain = lib.strings.concatStringsSep "," (lib.lists.forEach dcList (x: "dc=" + x));

  dovecotSecretPath = "/run/dovecot2-secret";
  ldapDefaultConf = pkgs.writeText "dovecot-ldap.conf.ext" ''
    ldap_version = 3
    auth_bind_userdn = uid=%u,ou=mail,${ldapDomain}
    auth_bind = yes
    hosts = ${cfg.domain}
    dn = cn=admin,${ldapDomain}
    base = ou=mail,${ldapDomain}
    pass_filter = (&(objectClass=inetorgperson)(uid=%u))

    user_filter = (&(objectClass=inetorgperson)(uid=%u))
  '';
  ldapSecretConf = "${dovecotSecretPath}/dovecot-ldap.conf.ext";
in
with builtins;
with lib;
{
  config = mkIf cfg.enable {
    # ===== Postfix ===== #
    environment.sessionVariables = {
      MAILDIR = cfg.mailDir;
    };

    services.postfix = {
      enable = true;
      hostname = cfg.domain;
      origin = cfg.origin;
      destination = cfg.destination;
      networks = cfg.networks;

      config = {
        virtual_uid_maps = [
          "static:${toString cfg.uid}"
        ];
        virtual_gid_maps = [
          "static:${toString cfg.gid}"
        ];

        virtual_mailbox_domains = [ cfg.domain ];
        virtual_transport = "lmtp:unix:private/dovecot-lmtp";

        tls_preempt_cipherlist = "yes";
        smtpd_use_tls = "yes";
        smtpd_tls_security_level = "may";
        smtpd_sasl_type = "dovecot";
        smtpd_sasl_path = "private/auth";
        smtpd_sasl_auth_enable = "yes";
        smtpd_recipient_restrictions = "permit_sasl_authenticated,reject";
        smtpd_relay_restrictions = "permit_mynetworks, permit_sasl_authenticated, reject_unauth_destination";

        home_mailbox = cfg.mailDir;
      };

      postmasterAlias = "root";
      extraAliases =
        ''
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

    # ===== Dovecot ===== #
    services.dovecot2 = {
      enable = lib.mkDefault true;
      enableImap = true;
      enablePop3 = true;
      enableLmtp = true;
      mailLocation = lib.mkDefault "maildir:${cfg.virtualMailDir}";
      mailUser = "vmail";
      mailGroup = "vmail";
      sslServerKey = cfg.sslKey;
      sslServerCert = cfg.sslCert;
      sslCACert = config.security.pki.caBundle;

      extraConfig = ''
        log_path  = /var/log/dovecot.log
        auth_debug = yes
        mail_debug = yes

        auth_mechanisms = plain login
        ssl = yes
        ssl_dh_parameters_length = 2048
        ssl_cipher_list = ALL:!LOW:!SSLv2:!EXP:!aNULL
        ssl_prefer_server_ciphers = yes

        service auth {
          unix_listener ${config.services.postfix.config.queue_directory}/private/auth {
            mode = 0660
            user = ${config.services.postfix.user}
            group = ${config.services.postfix.group}
          }
        }

        service lmtp {
          unix_listener ${config.services.postfix.config.queue_directory}/private/dovecot-lmtp {
            mode = 0600
            user = ${config.services.postfix.user}
            group = ${config.services.postfix.group}
          }
        }

        passdb ldap {
          driver = ldap
          args = ${ldapSecretConf}
        }

        userdb {
          driver = static
          args = uid=${toString cfg.uid} gid=${toString cfg.gid} home=${cfg.virtualMailDir}/%d/%n/
        }

        lda_mailbox_autosubscribe = yes
        lda_mailbox_autocreate = yes
      '';
    };

    systemd.services.dovecot2 = {
      serviceConfig = {
        RuntimeDirectory = [ "dovecot2-secret" ];
        RuntimeDirectoryMode = "0640";
        ExecStartPre = [
          ''${pkgs.busybox.out}/bin/mkdir -p ${cfg.virtualMailDir}''
          ''${pkgs.busybox.out}/bin/chown -R vmail:vmail ${cfg.virtualMailDir}''
          ''${pkgs.busybox.out}/bin/chmod 770 ${cfg.virtualMailDir}''
          ''${pkgs.busybox.out}/bin/sh -c "${pkgs.busybox.out}/bin/cat ${ldapDefaultConf} ${cfg.dovecot.ldapFile} > ${ldapSecretConf}"''
        ];
      };
    };

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
            "${pkgs.openldap}/etc/schema/nis.ldif"
          ];

          "olcDatabase={1}mdb".attrs = {
            objectClass = [
              "olcDatabaseConfig"
              "olcMdbConfig"
            ];

            olcDatabase = "{1}mdb";
            olcDbDirectory = "/var/lib/openldap/data";
            olcSuffix = "${ldapDomain}";

            olcRootDN = "cn=admin,${ldapDomain}";
            olcRootPW.path = cfg.openldap.passwordFile;

            olcAccess = [
              ''
                {0}to attrs=userPassword
                  by dn="cn=admin,${ldapDomain}" read
                  by self write
                  by anonymous auth
                  by * none
              ''
              ''
                {1}to *
                  by * read
              ''
            ];
          };
        };
      };
    };

    # Openldap auto create baseDN
    environment.etc."openldap/base.ldif" = {
      mode = "0770";
      user = config.services.openldap.user;
      group = config.services.openldap.group;
      text = ''
        dn: ${ldapDomain}
        objectClass: top
        objectClass: domain
        dc: ${elemAt dcList 0}
      '';
    };

    systemd.services.openldap-init-base = {
      wantedBy = [ "openldap.service" ];
      requires = [ "openldap.service" ];
      after = [ "openldap.service" ];
      serviceConfig = {
        User = config.services.openldap.user;
        Group = config.services.openldap.group;
        Type = "oneshot";
        ExecStart =
          let
            dcScript = pkgs.writeShellScriptBin "openldap-init" ''
              BASE_DN="${ldapDomain}"
              LDIF_FILE="/etc/openldap/base.ldif"
              ADMIN_DN="cn=admin,${ldapDomain}"
              ${pkgs.openldap}/bin/ldapsearch -x -b "$BASE_DN" -s base "(objectclass=*)" > /dev/null 2>&1

              if [ $? -ne 0 ]; then
                echo "Base DN $BASE_DN not exist, import $LDIF_FILE"
                ${pkgs.openldap}/bin/ldapadd -x -D "$ADMIN_DN" -y ${cfg.openldap.passwordFile} -W -f "$LDIF_FILE"
              else
                echo "Base DN $BASE_DN exists, skip"
              fi
            '';
          in
          "${dcScript}/bin/openldap-init";
      };
    };

    # ===== Firewall ===== #
    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [
      25 # SMTP
      465 # SMTPS
      587 # STARTTLS
      143 # IMAP STARTTLS
      993 # IMAPS
      110 # POP3 STARTTLS
      995 # POP3S
    ];

    # ===== Virtual Mail User ===== #
    users.groups.vmail = {
      gid = cfg.gid;
    };

    users.users.vmail = {
      uid = cfg.uid;
      group = "vmail";
    };

    virtualisation = mkIf cfg.openldap.enableWebUI {
      docker = {
        enable = lib.mkDefault true;
        rootless = {
          enable = true;
          setSocketVariable = true;
        };
      };

      oci-containers = {
        backend = "docker";
        containers = {
          lam = {
            image = "ghcr.io/ldapaccountmanager/lam:9.2";
            extraOptions = [ "--network=host" ];
            autoStart = true;
            environment = {
              LDAP_DOMAIN = cfg.domain;
              LDAP_SERVER = "ldap://${cfg.domain}";
              LDAP_USERS_DN = "ou=mail,${ldapDomain}";
            };
          };
        };
      };
    };
  };
}
