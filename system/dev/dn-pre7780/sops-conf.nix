{ config, lib, ... }:
let
  inherit (lib) optionalAttrs mkIf hasAttr;
in
{
  sops = {
    secrets = {
      "wireguard/wg0.conf" = { };
      "nextcloud/adminPassword" = mkIf config.services.nextcloud.enable {
        owner = "nextcloud";
        group = "nextcloud";
      };
      "openldap/adminPassword" = mkIf config.services.openldap.enable {
        owner = config.users.users.openldap.name;
        group = config.users.users.openldap.group;
        mode = "0660";
      };
      "lam/env" = { };
      "dovecot/openldap" = mkIf (config.services.postfix.enable && config.services.openldap.enable) {
        owner = config.services.dovecot2.user;
        group = config.services.dovecot2.group;
        mode = "0660";
      };

      "netbird/oidc/secret" = mkIf config.services.netbird.server.dashboard.enable {
        owner = "netbird";
      };

      "netbird/coturn/password" = mkIf config.services.netbird.server.coturn.enable {
        owner = "turnserver";
        key = "netbird/oidc/secret";
      };
      "netbird/dataStoreKey" = mkIf config.services.netbird.server.management.enable {
        owner = "netbird";
      };
      "acme/pdns" = mkIf (hasAttr "acme" config.users.users) {
        owner = "acme";
      };
    }
    // (optionalAttrs config.services.stalwart-mail.enable (
      let
        inherit (config.users.users.stalwart-mail) name group;
        owner = name;
      in
      {
        "stalwart/adminPassword" = {
          inherit group owner;
        };
        "stalwart/tsig" = {
          inherit group owner;
        };
        "stalwart/db" = {
          inherit group owner;
        };
        "stalwart/dkimKey" = {
          inherit group owner;
        };
        "cloudflare/secret" = {
          inherit group owner;
        };
        "stalwart/ldap" = {
          inherit group owner;
        };
      }
    ));
  };
}
