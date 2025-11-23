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
      "nextcloud/signaling.conf" = mkIf config.services.nextcloud.enable {
        owner = "signaling";
        group = "signaling";
        mode = "0640";
      };
      "nextcloud/whiteboard" = mkIf config.services.nextcloud.enable {
        owner = "nextcloud";
      };

      "lam/env" = { };

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
      "crowdsec/lapi.yaml" = mkIf config.services.crowdsec.enable {
        owner = "crowdsec";
        mode = "0600";
      };
      "crowdsec/capi.yaml" = mkIf config.services.crowdsec.enable {
        owner = "crowdsec";
        mode = "0600";
      };
      "crowdsec/consoleToken" = mkIf config.services.crowdsec.enable {
        owner = "crowdsec";
        mode = "0600";
      };
      "cloudflare/secret" = mkIf (hasAttr "acme" config.users.users) {
        owner = "acme";
        mode = "0600";
      };
      "rspamd" = mkIf config.services.rspamd.enable {
        owner = config.services.rspamd.user;
        group = config.services.rspamd.group;
        mode = "0660";
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
        "stalwart/ldap" = {
          inherit group owner;
        };
      }
    ));
  };
}
