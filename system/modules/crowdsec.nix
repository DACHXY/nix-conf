{
  lapiCred,
  capiCred,
  consoleToken,
  trusted_ips ? [ ],
  extraAcq ? [ ],
  extraJournal ? [ ],
  enableServer ? false,
  enablePrometheus ? true,
}:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkDefault mkIf;
  mkJournalFilter = service: {
    journalctl_filter = [
      "_SYSTEMD_UNIT=${service}"
    ];
    labels = {
      type = "syslog";
    };
    source = "journalctl";
  };

  # ==== Default Services ==== #
  services = map (x: mkJournalFilter x) [
    "sshd.service"
  ];

  extraServices = map (x: mkJournalFilter x) extraJournal;
in
{
  services.postgresql = {
    enable = mkDefault true;
    ensureDatabases = [ config.services.crowdsec.user ];
    ensureUsers = [
      {
        name = config.services.crowdsec.user;
        ensureDBOwnership = true;
      }
    ];
  };

  services.crowdsec = {
    enable = true;
    settings.general = {
      prometheus = {
        enabled = enablePrometheus;
      };
      db_config = {
        type = "postgresql";
        db_name = config.services.crowdsec.user;
        db_path = "/var/run/postgresql";
        user = config.services.crowdsec.user;
        sslmode = "disable";
        flush.max_items = 5000;
        flush.max_age = "7d";
      };
      api.client = {
        insecure_skip_verify = false;
      };
      api.server = mkIf enableServer {
        enable = true;
        listen_uri = "127.0.0.1:31005";
        trusted_ips = [
          "127.0.0.1"
          "10.0.0.0/24"
          "::1"
        ]
        ++ trusted_ips;
      };
    };
    settings = {
      lapi.credentialsFile = lapiCred;
      capi.credentialsFile = capiCred;
      console.tokenFile = consoleToken;
    };
    localConfig = {
      acquisitions = services ++ extraServices ++ extraAcq;
    };
    hub = {
      scenarios = [
        "crowdsecurity/ssh-bf"
        "crowdsecurity/ssh-generic-test"
        "crowdsecurity/http-generic-test"
      ];
      postOverflows = [ "crowdsecurity/auditd-nix-wrappers-whitelist-process" ];
      parsers = [ "crowdsecurity/sshd-logs" ];
      collections = [ "crowdsecurity/linux" ];
      appSecRules = [ "crowdsecurity/base-config" ];
      appSecConfigs = [ "crowdsecurity/appsec-default" ];
    };
    autoUpdateService = true;
  };
}
