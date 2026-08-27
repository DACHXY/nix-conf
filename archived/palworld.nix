{ ... }:
{
  configurations.nixos.dn-server.module =
    {
      pkgs,
      config,
      ...
    }:
    let
      username = config.my.user.name;
      workDir = "/home/${username}/.steam/steam/steamapps/common/PalServer";
    in
    {
      sops.secrets."palworld/env" = {
        owner = username;
        mode = "0400";
      };

      networking.firewall.allowedUDPPorts = [ 8211 ];

      systemd.user.services.pal-world-update = {
        wantedBy = [ "default.target" ];

        path = with pkgs; [
          jq
          steamcmd
          curl
        ];

        script = ''
          set -euo pipefail

          if [ ! -d "$STATE_DIR" ]; then
            echo "Error: STATE_DIR does not exist: $STATE_DIR" >&2
            exit 1
          fi

          BUILDID_FILE="$STATE_DIR/.buildid"

          function shutdownServer {
            curl -u "$SECRET_TOKEN" -L -X POST "$API_ENDPOINT/shutdown" \
              -H "Content-Type: application/json" \
              --data-raw "$(jq -n --arg waittime "$1" '{
                "waittime": $waittime,
                "message": "Server will shutdown in $waittime seconds."
              }')"
          }

          function sendMsg {
            curl -u "$SECRET_TOKEN" -L -X POST "$API_ENDPOINT/announce" \
              -H "Content-Type: application/json" \
              --data-raw "$(jq -n --arg msg "$1" '{message: $msg}')"
          }

          function getBuildId {
            curl -fsSL "$RSS_URL" |
              grep -m1 '<guid' |
              sed -E 's/.*build#([0-9]+).*/\1/'
          }

          function updateGame {
            steamcmd \
              +login anonymous \
              +app_update "$APP_ID" \
              +quit
          }

          echo "Getting last build Id..."
          latest_buildid=$(getBuildId)
          echo "Latest buildid: $latest_buildid"

          if [ -z "$latest_buildid" ]; then
              echo "Failed to get buildid"
              exit 1
          fi

          if [ ! -f "$BUILDID_FILE" ]; then
              echo "$latest_buildid" > "$BUILDID_FILE"
              echo "Initialized buildid: $latest_buildid"
              exit 0
          fi

          current_buildid=$(cat "$BUILDID_FILE")

          if [ "$latest_buildid" != "$current_buildid" ]; then
            echo "Update available: $current_buildid -> $latest_buildid"

            sendMsg "Server update available."
            shutdownServer 30
            sleep 30

            systemctl --user stop "$SERVICE_NAME"

            updateGame

            echo "$latest_buildid" > "$BUILDID_FILE"

            systemctl --user start "$SERVICE_NAME"

            sendMsg "Server update completed. Running build $latest_buildid"

          else
            echo "Already latest: $current_buildid"
          fi
        '';

        serviceConfig = {
          Type = "oneshot";
          EnvironmentFile = [
            config.sops.secrets."palworld/env".path
          ];
        };

        environment = {
          API_ENDPOINT = "http://localhost:8212/v1/api";
          APP_ID = "2394010";
          STATE_DIR = workDir;
          SERVICE_NAME = "pal-world-server.service";
          RSS_URL = "https://steamdb.info/api/PatchnotesRSS/?appid=2394010";
        };
      };

      systemd.user.timers.pal-world-update = {
        wantedBy = [ "timers.target" ];

        timerConfig = {
          OnCalendar = "*:0/30";
          Persistent = true;
          RandomizedDelaySec = "5m";
        };
      };

      systemd.user.services.pal-world-server = {
        wantedBy = [ "default.target" ];

        script = ''
          ./PalServer.sh
        '';

        serviceConfig = {
          WorkingDirectory = workDir;
          Restart = "on-failure";
          RestartSec = 10;
        };
      };
    };
}
