{
  lib,
  pkgs,
  helper,
  config,
  ...
}:
let
  inherit (lib) mkMerge;
  inherit (config.networking) domain;

  # ==== Add hosts here ===== #
  hostConfigs = [
    {
      address = "100.104.37.55";
      email = "dachxy@dnywe.com";
    }
  ];

  mkSystemdUnit =
    host:
    let
      srvName = "${host.address}-netbird-keepalive";

      sendMailBin = (
        helper.sendMail {
          username = "$MAIL_USERNAME";
          password = "$MAIL_PASSWORD";
          server = "https://stalwart.${domain}";
          to = "${host.email}";
          from = "netbird@dnywe.com";
          subject = "Unreachable: ${host.address}";
          content = "Trigger shortcut to reconnect.";
        }
      );
    in
    {
      timers."${srvName}" = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "10s";
          OnUnitActiveSec = "30s";
          Unit = "${srvName}.service";
        };
      };

      services."${srvName}" = {
        path = with pkgs; [
          curl
          iputils
          sendMailBin
        ];
        serviceConfig = {
          EnvironmentFile = [
            config.sops.templates."netbird-mail-env".path
          ];
          RuntimeDirectory = [ srvName ];
        };
        script = ''
          STATE_FILE="/run/${srvName}.down"
          if ! ping -c 8 -W 2 -q "${host.address}" > /dev/null 2>&1; then

            sleep 5

            if ! ping -c 8 -W 2 -q "${host.address}" > /dev/null 2>&1; then

              # Debounce
              if [ ! -f "$STATE_FILE" ]; then
                sendMail
                echo "failed to reach"
                touch "$STATE_FILE"
              fi
            fi
          else
            rm -f "$STATE_FILE"
          fi
        '';
        serviceConfig = {
          Type = "oneshot";
          User = "root";
        };
      };
    };
in
{
  sops.secrets = {
    "netbird/mail/username" = { };
    "netbird/mail/password" = { };
  };

  sops.templates."netbird-mail-env" = {
    content = ''
      MAIL_USERNAME=${config.sops.placeholder."netbird/mail/username"}
      MAIL_PASSWORD=${config.sops.placeholder."netbird/mail/password"}
    '';
  };

  systemd = mkMerge (map mkSystemdUnit hostConfigs);
}
