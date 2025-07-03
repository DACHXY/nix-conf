{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.mail-server;
  mailDir = "~/Maildir";
  mailLocPrefix = "/var/mail/vhosts";
  mailLoc = "${mailLocPrefix}/%d/%n";
in
with lib;
{
  config =
    with cfg;
    mkIf enable {
      # ===== Postfix ===== #
      environment.sessionVariables = {
        MAILDIR = mailDir;
      };

      services.postfix = {
        enable = true;
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
    };

  options.services.mail-server = {
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

    domain = mkOption {
      type = with types; uniq str;
      default = config.networking.fqdn;
      description = "Domain name used for mail server";
    };

    destinations = mkOption {
      type = with types; listOf str;
      default = [ ];
      description = "Postfix destination";
    };

    networks = mkOption {
      type = with types; listOf str;
      default = [ ];
      description = "Postfix networks";
    };

  };

}
