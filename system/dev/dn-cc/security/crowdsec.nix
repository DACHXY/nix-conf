{ config, ... }:
let
  inherit (config.sops) secrets;
in
{
  sops.secrets = {
    "crowdsec/token" = {
      owner = "crowdsec";
      group = "crowdsec";
      mode = "640";
      sopsFile = ../../public/sops/dn-secret.yaml;
    };
    "crowdsec/lapi.yaml" = {
      owner = "crowdsec";
      group = "crowdsec";
      mode = "640";
      sopsFile = ../../public/sops/dn-secret.yaml;
    };
    "crowdsec/capi.yaml" = {
      owner = "crowdsec";
      group = "crowdsec";
      mode = "640";
      sopsFile = ../../public/sops/dn-secret.yaml;
    };
  };

  services.crowdsec = {
    enable = true;
    settings = {
      lapi.credentialsFile = secrets."crowdsec/lapi.yaml".path;
      capi.credentialsFile = secrets."crowdsec/capi.yaml".path;
    };
    autoUpdateService = true;
    hub = {
      collections = [
        "crowdsecurity/http-cve"
        "crowdsecurity/base-http-scenarios"
        "crowdsecurity/linux"
      ];
      scenarios = [
        "crowdsecurity/ssh-bf"
        "crowdsecurity/ssh-generic-test"
        "crowdsecurity/http-generic-test"
      ];
      postOverflows = [ "crowdsecurity/auditd-nix-wrappers-whitelist-process" ];
      parsers = [ "crowdsecurity/sshd-logs" ];
      appSecRules = [ "crowdsecurity/base-config" ];
      appSecConfigs = [ "crowdsecurity/appsec-default" ];
    };

    localConfig = {
      acquisitions = [
        {
          source = "file";
          filenames = [ "/var/log/nginx/access.log" ];
          labels = {
            type = "nginx";
          };
        }
        {
          journalctl_filter = [
            "_SYSTEMD_UNIT=sshd.service"
          ];
          labels = {
            type = "syslog";
          };
          source = "journalctl";
        }
      ];
    };
  };

  services.crowdsec-firewall-bouncer = {
    enable = true;
  };
}
