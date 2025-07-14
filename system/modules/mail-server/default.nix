{
  config,
  lib,
  ...
}:
with lib;
{
  options.mail-server = {
    enable = mkEnableOption "mail-server";

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = ''
        This option results in following configuration:

        networking.firewall.allowedTCPPorts = [
          25  # SMTP
          465 # SMTPS
          587 # STARTTLS
          143 # IMAP STARTTLS
          993 # IMAPS
          110 # POP3 STARTTLS
          995 # POP3S
        ];
      '';
    };

    extraAliases = mkOption {
      type = with types; str;
      default = "";
      description = "Extra aliases";
      example = ''
        something: root
        gender: root
      '';
    };

    mailDir = mkOption {
      type = with types; uniq str;
      description = "Path to store local mails";
      default = "~/Maildir";
      example = "~/Maildir";
    };

    virtualMailDir = mkOption {
      type = with types; path;
      description = "Path to store virtual mails";
      default = "/var/mail/vhosts";
      example = "/var/mail/vmails";
    };

    uid = mkOption {
      type = with types; int;
      default = 5000;
      description = "UID for \"vmail\"";
    };

    gid = mkOption {
      type = with types; int;
      default = 5000;
      description = "GID for \"vmail\"";
    };

    domain = mkOption {
      type = with types; uniq str;
      default = config.networking.fqdn;
      description = "Domain name used for mail server";
    };

    origin = mkOption {
      type = with types; uniq str;
      default = "";
      description = "Origin to use in outgoing e-mail. Leave blank to use hostname.";
    };

    destination = mkOption {
      type = with types; listOf str;
      default = [ ];
      description = "Postfix destination";
    };

    networks = mkOption {
      type = with types; listOf str;
      default = [ ];
      description = "Postfix networks";
    };

    sslKey = mkOption {
      type = with types; path;
      description = "Path to the SSL key";
      example = "/etc/ssl/private/key.pem";
    };

    sslCert = mkOption {
      type = with types; path;
      description = "Path to the SSL Certification";
      example = "/etc/ssl/private/cert.pem";
    };

    dovecot = {
      ldapFile = mkOption {
        type = with types; path;
        description = "Path to the dovecot openldap config file";
        example = "/run/secrets/dovecot/ldap";
      };
    };

    openldap = {
      passwordFile = mkOption {
        type = with types; path;
        description = "Path to the openldap admin password file";
        example = "/run/secrets/openldap/passwd";
      };

      enableWebUI = mkOption {
        type = types.bool;
        default = false;
        description = "Use docker to run Ldap Account Manager for using web ui.";
      };
    };
  };

  imports = [
    ./server.nix
  ];
}
