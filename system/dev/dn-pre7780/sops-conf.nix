{ config, lib, ... }:
let
  inherit (lib) optionalAttrs;
in
{
  sops = {
    secrets = {
      "wireguard/conf" = { };
      "nextcloud/adminPassword" = lib.mkIf config.services.nextcloud.enable {
        owner = "nextcloud";
        group = "nextcloud";
      };
      "openldap/adminPassword" = lib.mkIf config.services.openldap.enable {
        owner = config.users.users.openldap.name;
        group = config.users.users.openldap.group;
        mode = "0660";
      };
      "lam/env" = { };
      "dovecot/openldap" = lib.mkIf (config.services.postfix.enable && config.services.openldap.enable) {
        owner = config.services.dovecot2.user;
        group = config.services.dovecot2.group;
        mode = "0660";
      };

      # "acme/pdns" = {
      #   mode = "0660";
      #   owner = "acme";
      #   group = "acme";
      # };
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
