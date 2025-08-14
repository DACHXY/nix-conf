{
  config,
  lib,
  ...
}:
with lib;
{
  options.mail-server = {
    enable = mkEnableOption "mail-server";
    caFile = mkOption {
      type = types.path;
      default = config.security.pki.caBundle;
      description = ''
        Extra CA certification to trust;
      '';
    };

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

    rootAlias = mkOption {
      type = with types; uniq str;
      default = "";
      description = "Root alias";
      example = ''
        <your username>
      '';
    };

    virtual = mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        Entries for the virtual alias map, cf. man-page {manpage}`virtual(5)`.
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

    oauth = {
      username = mkOption {
        type = with types; uniq str;
        default = "keycloak";
        description = "Keycloak username";
      };

      passwordFile = mkOption {
        type = with types; path;
        description = "Path to the keycloak password file";
        example = "/run/secrets/keycloak/password";
      };
    };

    ldap = {
      passwordFile = mkOption {
        type = with types; path;
        description = "Path to the openldap password file";
        example = "/run/secrets/ldap/password";
      };

      webEnv = mkOption {
        type = with types; path;
        description = "Path to phpLDAPadmin env file";
        example = "/run/secrets/ldap/env";
      };
    };

    rspamd = {
      trainerSecret = mkOption {
        type = with types; path;
        description = "Path to rspamd trainer secret";
        example = "/run/secrets/rspamd-trainer/secret";
      };
      port = mkOption {
        type = with types; int;
        default = 11334;
        description = "Port for rspamd webUI";
      };
    };
  };

  imports = [
    ./server.nix
  ];
}
