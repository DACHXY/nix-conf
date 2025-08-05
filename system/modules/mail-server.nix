{
  fqdn ? null,
  origin ? null,
  destination ? null,
  networks ? null,
  rootAlias ? "root",
  extraAliases ? "",
  enableOpenldap ? true,
  dovecotLdapSecretFile,
  openldapAdmPassPath,
  sslKeyPath,
  sslCertPath,
}:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  postfixFqdn = if fqdn != null then fqdn else config.networking.fqdn;
  postfixOrigin = if origin != null then origin else postfixFqdn;
  postfixDest =
    if destination != null then
      destination
    else
      [
        "localhost"
        "localhost.${postfixFqdn}"
      ];

  postfixNet =
    if networks != null then
      networks
    else
      [
        "127.0.0.0/8"
        "[::1]/128"
      ];

  postfixMailDir = "~/Maildir";
  mailLocationPrefix = "/var/mail/vhosts";
  mailLocation = "${mailLocationPrefix}/%d/%n/";

  dcList = lib.strings.splitString "." postfixFqdn;
  domain = lib.strings.concatStringsSep "," (lib.lists.forEach dcList (x: "dc=" + x));

  dovecotSecretPath = "/run/dovecot2-secret";
  ldapSecretConf = "${dovecotSecretPath}/dovecot-ldap.conf.ext";

  ldapDefaultConf = pkgs.writeText "dovecot-ldap.conf.ext" ''
    ldap_version = 3
    auth_bind_userdn = uid=%u,ou=mail,${domain}
    auth_bind = yes
    hosts = ${postfixFqdn}
    dn = cn=admin,${domain}
    base = ou=mail,${domain}
    pass_filter = (&(objectClass=inetorgperson)(uid=%u))

    user_filter = (&(objectClass=inetorgperson)(uid=%u))
  '';

  mailUser = "vmail";
in
with builtins;
{
  environment.sessionVariables = {
    MAILDIR = postfixMailDir;
  };

  networking.firewall.allowedTCPPorts = [
    25 # SMTP
    465 # SMTPS
    587 # STARTTLS
    80
    143 # IMAP STARTTLS
    993 # IMAPS
    110 # POP3 STARTTLS
    995 # POP3S
  ];

  users.groups.${mailUser} = {
    gid = 5000;
  };

  users.users.${mailUser} = {
    isSystemUser = true;
    uid = 5000;
    group = mailUser;
  };

  services.postfix = {
    inherit rootAlias;

    enable = lib.mkDefault true;
    hostname = postfixFqdn;
    origin = postfixOrigin;
    destination = postfixDest;
    networks = postfixNet;
    sslKey = sslKeyPath;
    sslCert = sslCertPath;

    config = {
      virtual_uid_maps = [
        "static:${toString config.users.users.vmail.uid}"
      ];
      virtual_gid_maps = [
        "static:${toString config.users.groups.vmail.gid}"
      ];
      virtual_mailbox_domains = [ postfixFqdn ];
      virtual_transport = "lmtp:unix:private/dovecot-lmtp";

      tls_preempt_cipherlist = "yes";
      smtpd_use_tls = "yes";
      smtpd_tls_security_level = "may";
      smtpd_sasl_type = "dovecot";
      smtpd_sasl_path = "private/auth";
      smtpd_sasl_auth_enable = "yes";
      smtpd_recipient_restrictions = "permit_sasl_authenticated,reject";
      smtpd_relay_restrictions = "permit_mynetworks, permit_sasl_authenticated, reject_unauth_destination";

      home_mailbox = postfixMailDir;
    };

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
    + extraAliases;
  };

  services.dovecot2 = {
    enable = lib.mkDefault true;
    enableImap = true;
    enablePop3 = true;
    enableLmtp = true;
    mailLocation = lib.mkDefault "maildir:${mailLocation}";
    mailUser = mailUser;
    mailGroup = mailUser;
    sslServerKey = sslKeyPath;
    sslServerCert = sslCertPath;
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
        args = uid=${mailUser} gid=${mailUser} home=${mailLocation}
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
        ''${pkgs.busybox.out}/bin/mkdir -p ${mailLocationPrefix}''
        ''${pkgs.busybox.out}/bin/chown -R ${mailUser}:${mailUser} ${mailLocationPrefix}''
        ''${pkgs.busybox.out}/bin/chmod 770 ${mailLocationPrefix}''
        ''${pkgs.busybox.out}/bin/sh -c "${pkgs.busybox.out}/bin/cat ${ldapDefaultConf} ${dovecotLdapSecretFile} > ${ldapSecretConf}"''
      ];
    };
  };

  services.openldap = lib.mkIf enableOpenldap {
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
          olcSuffix = "${domain}";

          olcRootDN = "cn=admin,${domain}";
          olcRootPW.path = openldapAdmPassPath;

          olcAccess = [
            ''
              {0}to attrs=userPassword
                by dn="cn=admin,${domain}" read
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

  environment.etc."openldap/base.ldif" = {
    mode = "0770";
    user = config.services.openldap.user;
    group = config.services.openldap.group;
    text = ''
      dn: ${domain}
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
            BASE_DN="${domain}"
            LDIF_FILE="/etc/openldap/base.ldif"
            ADMIN_DN="cn=admin,${domain}"
            ${pkgs.openldap}/bin/ldapsearch -x -b "$BASE_DN" -s base "(objectclass=*)" > /dev/null 2>&1

            if [ $? -ne 0 ]; then
              echo "Base DN $BASE_DN not exist, import $LDIF_FILE"
              ${pkgs.openldap}/bin/ldapadd -x -D "$ADMIN_DN" -y ${openldapAdmPassPath} -W -f "$LDIF_FILE"
            else
              echo "Base DN $BASE_DN exists, skip"
            fi
          '';
        in
        "${dcScript}/bin/openldap-init";
    };
  };

  virtualisation = {
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
            LDAP_DOMAIN = postfixFqdn;
            LDAP_SERVER = "ldap://${postfixFqdn}";
            LDAP_USERS_DN = "ou=mail,${domain}";
          };
        };
      };
    };
  };
}
