{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) getExe;

  notifyUser = pkgs.writeShellScriptBin "wg0-watchdog-notify-user" ''
    is_wg_active() {
      systemctl is-active wg-quick-wg0.service >/dev/null 2>&1
      return $?
    }

    if is_wg_active; then
      notify-send -u critical -a Wireguard "Endpoint up, wireguard resumed."
    else
      notify-send -u critical -a Wireguard "Endpoint down, wireguard stopped."
    fi
  '';

  watchDog = pkgs.writeShellScriptBin "wg0-watchdog" ''
    TARGET_CONF="$1"
    PING_INTERVAL=1
    PING_TIMEOUT=1
    PING_COUNT=1

    set -euo pipefail

    error_with_msg() {
      echo "$1"
      echo "Exiting"
      exit 1
    }

    notify() {
      users=$(loginctl list-users --json=short | jq -r '.[].user')
      for user in $users; do
        systemctl --machine=danny@.host --user start wg0-notify-user
      done
    }

    get_ip_from_conf() {
      sed -n "s/Endpoint[[:space:]]*=[[:space:]]*\(.*\):[0-9]*/\\1/p" "$1"
    }

    check_health() {
      ping -c "$PING_COUNT" -W "$PING_TIMEOUT" $1 >/dev/null 2>&1
      return $?
    }

    is_wg_active() {
      systemctl is-active wg-quick-wg0.service >/dev/null 2>&1
      return $?
    }

    start_wg() {
      systemctl start wg-quick-wg0.service >/dev/null
    }

    stop_wg() {
      systemctl stop wg-quick-wg0.service >/dev/null
    }

    if [ ! -e "$TARGET_CONF" ]; then
      error_with_msg "Target wireguard configuration not exist: $TARGET_CONF"
    fi

    TARGET_IP=$(get_ip_from_conf "$TARGET_CONF")

    if [ -z "$TARGET_IP" ]; then
      error_with_msg "IP not found"
    fi

    echo "Start detecting..."

    while true; do
      if check_health "$TARGET_IP"; then
        if ! is_wg_active; then
          start_wg
          echo "Endpoint up, wireguard resumed."
          notify
        fi
      else
        if is_wg_active; then
          stop_wg
          echo "Endpoint down, wireguard stopped."
          notify
        fi
      fi

      sleep $PING_INTERVAL
    done
  '';
in
{
  sops.secrets."wireguard/wg0.conf" = { };

  networking = {
    firewall = {
      allowedUDPPorts = [ 51820 ];
    };
    wg-quick.interfaces.wg0.configFile = config.sops.secrets."wireguard/wg0.conf".path;
  };

  systemd.services.wg0-watchdog = {
    wantedBy = [ "wg-quick-wg0.service" ];
    after = [ "wg-quick-wg0.service" ];
    path = with pkgs; [
      jq
    ];
    serviceConfig = {
      ExecStart = "${getExe watchDog} \"${config.sops.secrets."wireguard/wg0.conf".path}\"";
      RestartSec = 5;
      TimeoutStopSec = 0;
    };
  };

  systemd.user.services.wg0-notify-user = {
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${getExe notifyUser}";
    };
    path = with pkgs; [
      libnotify
    ];
  };
}
