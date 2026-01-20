{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (pkgs.writers) writeTOML;
  inherit (lib)
    mkIf
    mkOption
    mkEnableOption
    mkPackageOption
    types
    getExe
    ;
  cfg = config.services.velocity;
  defaultSettings = {
    config-version = "2.7";
    motd = "<#09add3>A Velocity Server";
    show-max-players = 500;
    online-mode = true;
    force-key-authentication = true;
    prevent-client-proxy-connections = false;
    player-info-forwarding-mode = "none";
    forwarding-secret-file = "forwarding.secret";
    announce-forge = false;
    kick-existing-players = false;
    ping-passthrough = "DISABLED";
    sample-players-in-ping = false;
    enable-player-address-logging = true;

    servers = {
    };

    forced-hosts = {
    };

    advanced = {
      compression-threshold = 256;
      compression-level = -1;
      login-ratelimit = 3000;
      connection-timeout = 5000;
      read-timeout = 30000;
      haproxy-protocol = false;
      tcp-fast-open = false;
      bungee-plugin-message-channel = true;
      show-ping-requests = false;
      failover-on-unexpected-server-disconnect = true;
      announce-proxy-commands = true;
      log-command-executions = false;
      log-player-connections = true;
      accepts-transfers = false;
      enable-reuse-port = false;
      command-rate-limit = 50;
      forward-commands-if-rate-limited = true;
      kick-after-rate-limited-commands = 0;
      tab-complete-rate-limit = 10;
      kick-after-rate-limited-tab-completes = 0;
    };

    query = {
      enabled = false;
      port = 25565;
      map = "Velocity";
      show-plugins = false;
    };
  };
in
{
  options.services.velocity = {
    enable = mkEnableOption "Enable the minecraft proxy";
    package = mkPackageOption pkgs "velocity" { };
    user = mkOption {
      type = types.str;
      default = "velocity";
    };
    group = mkOption {
      type = types.str;
      default = "velocity";
    };

    host = mkOption {
      type = types.str;
      default = "0.0.0.0";
    };

    port = mkOption {
      type = types.port;
      default = 25565;
    };

    openFirewall = mkEnableOption "Open firewall for velocity" // {
      default = true;
    };

    settings = mkOption {
      type =
        with types;
        attrsOf (oneOf [
          attrs
          str
          int
          bool
        ]);
      default = defaultSettings;
      apply =
        v:
        defaultSettings
        // {
          bind = "${cfg.host}:${toString cfg.port}";
        }
        // v;
    };
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];

    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
    };
    users.groups.${cfg.group} = { };

    systemd.services.velocity =
      let
        configFile = writeTOML "velocity.toml" cfg.settings;
      in
      {
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          User = cfg.user;
          Group = cfg.group;
          ExecStartPre =
            let
              configFilePath = "/var/lib/velocity/velocity.toml";
            in
            [
              "${pkgs.coreutils}/bin/cp ${configFile} ${configFilePath}"
              "${pkgs.coreutils}/bin/chmod 750 ${configFilePath}"
              "${pkgs.coreutils}/bin/chown ${cfg.user}:${cfg.group} ${configFilePath}"
            ];
          ExecStart = "${getExe cfg.package}";
          StateDirectory = "velocity";
          StateDirectoryMode = "0750";
          WorkingDirectory = "/var/lib/velocity";
        };
      };
  };
}
