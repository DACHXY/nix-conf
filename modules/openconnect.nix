{
  flake.modules.darwin.base =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      plugin = pkgs.writeShellScript "openconnect.1m.sh" ''
        # <xbar.title>Openconnect Manager</xbar.title>
        # <xbar.version>v1.0</xbar.version>
        # <xbar.desc>Manage multiple openconnect connections</xbar.desc>
        # <swiftbar.hideAbout>true</swiftbar.hideAbout>
        # <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
        # <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>
        # <swiftbar.hideDisablePlugin>false</swiftbar.hideDisablePlugin>
        # <swiftbar.hideSwiftBar>true</swiftbar.hideSwiftBar>

        # ── Configuration ────────────────────────────────────────────────────────────
        # Directory where sops-nix places the decrypted .conf files
        # Override via environment or nix-darwin module
        VPN_SECRETS_DIR="''${VPN_SECRETS_DIR:=$HOME/Documents/vpn-configs}"

        # Directory to store PID files for tracking active connections
        VPN_RUN_DIR="''${HOME}/.local/run/vpn"

        # openfortivpn binary — populated by nix wrapper script at install time
        OPENCONNECT="${lib.getExe pkgs.openconnect}"

        # Log directory
        VPN_LOG_DIR="''${HOME}/.local/log/vpn"

        # ── Bootstrap ────────────────────────────────────────────────────────────────
        mkdir -p "$VPN_RUN_DIR" "$VPN_LOG_DIR"

        # ── Helpers ──────────────────────────────────────────────────────────────────

        # Return the PID file path for an account
        pid_file() {
          local account="$1"
          echo "''${VPN_RUN_DIR}/''${account}.pid"
        }

        # Return the log file path for an account
        log_file() {
          local account="$1"
          echo "''${VPN_LOG_DIR}/''${account}.log"
        }

        # Check if a VPN is currently connected (process alive + ppp interface exists)
        is_connected() {
          local account="$1"
          local pf; pf="$(pid_file "$account")"
          [[ -f "$pf" ]] || return 1
          local pid; pid="$(cat "$pf")"
          sudo ${lib.getExe' pkgs.coreutils "kill"} -0 "$pid" 2>/dev/null || return 1
          return 0
        }

        # List all account names (basename without .conf) sorted
        list_accounts() {
          if [[ ! -d "$VPN_SECRETS_DIR" ]]; then
            return
          fi
          find "$VPN_SECRETS_DIR" -maxdepth 1 -name '*.conf'  \( -type l -o -type f \) \
            | sort \
            | xargs -I{} basename {} .conf
        }

        # Count connected accounts
        count_connected() {
          local n=0
          while IFS= read -r account; do
            is_connected "$account" && (( n++ )) || true
          done < <(list_accounts)
          echo "$n"
        }

        # ── Actions (invoked via bash= parameter) ───────────────────────────────────
        action_connect() {
          local account="$1"
          local conf="''${VPN_SECRETS_DIR}/''${account}.conf"
          local pf; pf="$(pid_file "$account")"
          local lf; lf="$(log_file "$account")"

          if is_connected "$account"; then
            echo "Already connected: $account" >&2
            exit 0
          fi

          local host user proto passfile
          host=$(     grep -E '^server='          "$conf" | cut -d= -f2-)
          user=$(     grep -E '^user='      "$conf" | cut -d= -f2-)
          proto=$(    grep -E '^protocol='      "$conf" | cut -d= -f2-)
          passfile=$( grep -E '^password-file=' "$conf" | cut -d= -f2-)
          servercert=$( grep -E '^servercert=' "$conf" | cut -d= -f2-)

          if [[ ! -f "$passfile" ]]; then
            echo "Password file not found: $passfile" >&2
            exit 1
          fi

          cat "$passfile" | sudo "$OPENCONNECT" \
            --protocol="$proto" \
            --user="$user" \
            --passwd-on-stdin \
            --background \
            --servercert="$servercert" \
            --pid-file="$pf" \
            "$host" \
          >> "$lf" 2>&1 &
        }

        action_disconnect() {
          local account="$1"
          local pf; pf="$(pid_file "$account")"

          if ! is_connected "$account"; then
            rm -f "$pf"
            exit 0
          fi

          local pid; pid="$(cat "$pf")"
          # Kill the process tree (openfortivpn spawns child processes)
          sudo ${lib.getExe' pkgs.coreutils "kill"} "$pid" 2>/dev/null || true
          # Give it a moment, then force-kill if needed
          sleep 1
          ${lib.getExe' pkgs.coreutils "kill"} -0 "$pid" 2>/dev/null && sudo ${lib.getExe' pkgs.coreutils "kill"} -9 "$pid" 2>/dev/null || true
          rm -f "$pf"
        }

        action_show_log() {
          local account="$1"
          local lf; lf="$(log_file "$account")"
          if [[ -f "$lf" ]]; then
            open -a Console "$lf"
          else
            osascript -e "display dialog \"No log found for ''${account}\" buttons {\"OK\"}"
          fi
        }

        action_disconnect_all() {
          while IFS= read -r account; do
            action_disconnect "$account"
          done < <(list_accounts)
        }

        # ── Dispatch action if called with arguments ─────────────────────────────────
        if [[ $# -ge 1 ]]; then
          case "$1" in
            connect)         action_connect        "$2" ;;
            disconnect)      action_disconnect     "$2" ;;
            disconnect_all)  action_disconnect_all      ;;
            show_log)        action_show_log       "$2" ;;
          esac
          sleep 3
          # Refresh the plugin after any action
          open "swiftbar://refreshplugin?name=vpn" 2>/dev/null || true
          exit 0
        fi

        # ── Build SwiftBar output ────────────────────────────────────────────────────
        SELF="$SWIFTBAR_PLUGIN_PATH"
        # Fallback when testing outside SwiftBar
        [[ -z "$SELF" ]] && SELF="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"

        connected_count=$(count_connected)
        total_count=$(list_accounts | wc -l | tr -d ' ')

        # ── Header ────────────────────────────────────────────────────────────────────
        if [[ "$connected_count" -gt 0 ]]; then
          echo " | color=primary sfimage=shield.fill"
        else
          echo " | color=primary sfimage=shield"
        fi

        echo "---"

        # ── Accounts list ─────────────────────────────────────────────────────────────
        if [[ "$total_count" -eq 0 ]]; then
          echo "No configs found in | color=gray"
          echo "''${VPN_SECRETS_DIR} | color=gray size=11"
          echo "---"
        else
          while IFS= read -r account; do
            if is_connected "$account"; then
              # Connected
              echo "''${account} | color=primary bash=''${SELF} param1=disconnect param2=''${account} terminal=false refresh=true sfimage=checkmark"
              echo "-- Disconnect | color=#fc5b5b bash=''${SELF} param1=disconnect param2=''${account} terminal=false refresh=true sfimage=delete.right sfconfig=ewogICAgImNvbG9ycyI6IFsiI2ZjNWI1YiJdCn0="
              echo "-- Show Log | bash=''${SELF} param1=show_log param2=''${account} terminal=false sfimage=doc.text"
            else
              # Disconnected
              echo "''${account} | color=primary bash=''${SELF} param1=connect param2=''${account} terminal=false refresh=true"
              echo "-- Connect | color=primary bash=''${SELF} param1=connect param2=''${account} terminal=false refresh=true sfimage=personalhotspot"
              echo "-- Show Log | bash=''${SELF} param1=show_log param2=''${account} terminal=false sfimage=doc.text"
            fi
          done < <(list_accounts)

          echo "---"

          # Bulk actions
          if [[ "$connected_count" -gt 0 ]]; then
            echo "Disconnect All | color=#fc5b5b bash=''${SELF} param1=disconnect_all terminal=false refresh=true sfimage=delete.right sfconfig=ewogICAgImNvbG9ycyI6IFsiI2ZjNWI1YiJdCn0="
          fi
        fi

        # ── Footer ────────────────────────────────────────────────────────────────────
        echo "Refresh | refresh=true sfimage=arrow.2.circlepath"
        echo "Configs: ''${VPN_SECRETS_DIR} | size=11 color=gray"
      '';
    in
    {
      environment.systemPackages = [ pkgs.openconnect ];

      environment.etc."sudoers.d/openconnect".text = ''
        ${config.my.user.name} ALL=(ALL) NOPASSWD: ${lib.getExe pkgs.openconnect} 
        ${config.my.user.name} ALL=(ALL) NOPASSWD: ${lib.getExe' pkgs.coreutils "kill"} 
      '';

      home-manager.users.${config.my.user.name} = {
        home.file."Documents/swiftbar-plugins/openconnect.1m.sh" = {
          executable = true;
          text = builtins.readFile plugin;
        };
      };
    };
}
