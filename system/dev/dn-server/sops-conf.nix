{ config, lib, ... }:
let
  inherit (lib) mkIf;
in
{
  sops = {
    secrets = {
      "wireguard/privateKey" = { };
      "nextcloud/adminPassword" = { };
      "step_ca/password" = { };
      vaultwarden = { };
      "oauth/password" = { };
      "ldap/password" = lib.mkIf config.mail-server.enable {
        mode = "0660";
        owner = config.services.openldap.user;
        group = config.services.openldap.group;
      };
      "ldap/env" = lib.mkIf config.mail-server.enable {
        mode = "0660";
        group = config.users.groups.docker.name;
      };
      "powerdns-admin/secret" = {
        mode = "0660";
        owner = "powerdnsadmin";
        group = "powerdnsadmin";
      };
      "powerdns-admin/salt" = {
        mode = "0660";
        owner = "powerdnsadmin";
        group = "powerdnsadmin";
      };
      powerdns = {
        mode = "0660";
        owner = "pdns";
        group = "pdns";
      };
      rspamd-trainer = { };
      "acme/env" = mkIf config.security.acme.acceptTerms {
        mode = "0660";
        owner = "acme";
        group = "acme";
      };
      "postsrsd/secret" = mkIf config.services.postsrsd.enable {
        mode = "0660";
        owner = config.services.postsrsd.user;
        group = config.services.postsrsd.group;
      };
      "grafana/password" = mkIf config.services.grafana.enable {
        mode = "0660";
        owner = "grafana";
        group = "grafana";
      };
      "grafana/client_secret" = mkIf config.services.grafana.enable {
        mode = "0660";
        owner = "grafana";
        group = "grafana";
      };
      "prometheus/powerdns/password" = mkIf config.services.prometheus.enable {
        mode = "0660";
        owner = "prometheus";
        group = config.users.users.prometheus.group;
      };
      "paperless/adminPassword" = mkIf config.services.paperless.enable {
        owner = config.services.paperless.user;
      };
    };
  };
}
