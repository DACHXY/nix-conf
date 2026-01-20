{ config, lib, ... }:
let
  inherit (lib) mkIf;
in
{
  sops.secrets = {
    "wireguard/privateKey" = { };
    "step_ca/password" = { };
    "oauth/password" = { };
    "oauth/adminEnv" = { };
    "ldap/password" = lib.mkIf config.mail-server.enable {
      mode = "0660";
      owner = config.services.openldap.user;
      group = config.services.openldap.group;
    };
    "ldap/env" = lib.mkIf config.mail-server.enable {
      mode = "0660";
      group = config.users.groups.docker.name;
    };
    rspamd-trainer = {
    };
    rspamd = mkIf config.services.rspamd.enable {
      owner = config.services.rspamd.user;
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
    "paperless/envFile" = mkIf config.services.paperless.enable {
      owner = config.services.paperless.user;
    };
    "atticd/secret" = mkIf config.services.atticd.enable { };
    "docmost" = { };
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
    "opencloud" = mkIf config.services.opencloud.enable {
      owner = config.services.opencloud.user;
      group = config.services.opencloud.group;
      mode = "0600";
    };
    "ntfy" = mkIf config.services.ntfy-sh.enable {
      owner = config.services.ntfy-sh.user;
      mode = "0600";
    };
  };
}
