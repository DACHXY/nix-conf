{
  configurations.nixos.dn-cscc.module =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      inherit (config.networking) hostName;
      # Lock the screen via noctalia when a stream ends (stream-side undo hook).
      sunshineLock = pkgs.writeShellScript "sunshine-lock" ''
        export PATH="${pkgs.noctalia}/bin:$PATH"
        WAYLAND_DISPLAY="''${WAYLAND_DISPLAY:-wayland-1}" noctalia msg session lock
      '';
      physicalOutputs = [
        {
          connector = "DP-1";
          criteria = "Dell Inc. DELL U2724DE 4C1XL04";
          mode = "2560x1440@120Hz";
          position = "0,0";
          scale = 1.0;
        }
        {
          connector = "HDMI-A-1";
          criteria = "Dell Inc. DELL U2422HE 3HFMNM3";
          mode = "1920x1080@60Hz";
          position = "2560,120";
          scale = 1.0;
        }
      ];

      kanshiPhysicalOutputs = map (o: builtins.removeAttrs o [ "connector" ]) physicalOutputs;
      physicalOnCmds = lib.concatMapStringsSep "\n" (
        o: "niri msg output ${o.connector} on"
      ) physicalOutputs;
      physicalOffCmds = lib.concatMapStringsSep "\n" (
        o: "niri msg output ${o.connector} off"
      ) physicalOutputs;

      modeWidth = mode: lib.toInt (builtins.head (builtins.match "([0-9]+)x.*" mode));
      positionX = pos: lib.toInt (builtins.head (builtins.match "([0-9]+),.*" pos));
      rightEdge = lib.foldl' (
        acc: o: lib.max acc (positionX o.position + modeWidth o.mode)
      ) 0 physicalOutputs;

      virtualOutput = {
        criteria = "DP-2";
        position = "${toString rightEdge},0";
        scale = 1.0;
      };

      normalProfile = {
        profile.name = hostName;
        profile.outputs = kanshiPhysicalOutputs ++ [
          {
            criteria = virtualOutput.criteria;
            status = "disable";
          }
        ];
      };

      streamProfile = {
        profile.name = "${hostName}-stream";
        profile.outputs = map (o: o // { status = "disable"; }) kanshiPhysicalOutputs ++ [
          (virtualOutput // { status = "enable"; })
        ];
      };

      displayToggle = pkgs.writeShellApplication {
        name = "sunshine-display-toggle";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.gnugrep
          pkgs.gawk
          pkgs.findutils
          config.programs.niri.package
        ];
        text = ''
          exec >>/tmp/sunshine-toggle.debug 2>&1  # ponytail: debug logging, remove once stream toggle is verified
          trap 'echo "=== pass ending, rc=$? at $(date +%T) ==="' EXIT
          echo "{on:''${1:-unset}} WAYLAND_DISPLAY=''${WAYLAND_DISPLAY:-unset} NIRI_SOCKET=''${NIRI_SOCKET:-unset} XDG_RUNTIME_DIR=''${XDG_RUNTIME_DIR:-unset} CLW=''${SUNSHINE_CLIENT_WIDTH:-unset}"
          # Sunshine runs as a systemd user service without WAYLAND_DISPLAY
          # set, so niri msg needs it to talk to the compositor IPC.
          export WAYLAND_DISPLAY="''${WAYLAND_DISPLAY:-wayland-1}"
          # niri IPC socket is niri.<wayland-display>.<pid>.sock; services
          # without NIRI_SOCKET pick the (single) running compositor's.
          if [ -z "''${NIRI_SOCKET:-}" ]; then
            NIRI_SOCKET="$(find "$XDG_RUNTIME_DIR" -maxdepth 1 -name "niri.''${WAYLAND_DISPLAY}.*.sock" -type s | head -n1)"
            export NIRI_SOCKET
          fi
          case "''${1:-}" in
            on)
              # Toggle outputs directly with niri; kanshi auto-activates the
              # matching profile (${hostName}-stream) from the resulting state.
              # kanshictl switch can't be used here because it requires the
              # profile to already match the current outputs.
              ${physicalOffCmds}
              niri msg output ${virtualOutput.criteria} on
              # Switch DP-2 to the resolution Moonlight requested
              # (SUNSHINE_CLIENT_WIDTH/HEIGHT/FPS, set by sunshine for prep-cmds).
              w="''${SUNSHINE_CLIENT_WIDTH:-0}"
              h="''${SUNSHINE_CLIENT_HEIGHT:-0}"
              fps="''${SUNSHINE_CLIENT_FPS:-0}"
              if [ "$w" -gt 0 ] && [ "$h" -gt 0 ]; then
                modes=$( { niri msg outputs \
                  | awk -v v="(${virtualOutput.criteria})" 'index($0,v){f=1;next} /^Output /{f=0} f' \
                  | grep -oE "''${w}x''${h}@[0-9.]+"; } | sort -u || true)
                if [ -n "$modes" ]; then
                  # Prefer a mode whose refresh rate matches the client; fall
                  # back to the first mode.  Do NOT pipe two writers into
                  # `head` -- the loser gets EPIPE and pipefail (set by
                  # writeShellApplication) turns that into exit 1.
                  mode=$(printf '%s\n' "$modes" | grep -E "@''${fps}([.]|$)" | head -n1 || true)
                  [ -n "$mode" ] || mode=$(printf '%s\n' "$modes" | head -n1)
                  niri msg output ${virtualOutput.criteria} mode "$mode" || true
                fi
              fi
              ;;
            off)
              ${physicalOnCmds}
              niri msg output ${virtualOutput.criteria} off
              # kanshi auto-activates ${hostName} once DP-2 is off and all
              # physical outputs are back on
              ;;
            *)
              echo "usage: $0 {on|off}" >&2
              exit 2
              ;;
          esac
        '';
      };
    in
    {
      home-manager.users.${config.my.user.name} = {
        services.kanshi = {
          enable = true;
          settings = [
            normalProfile
            streamProfile
          ];
        };
      };

      services.sunshine.settings.global_prep_cmd = builtins.toJSON [
        {
          do = "${displayToggle}/bin/sunshine-display-toggle on";
          undo = "${displayToggle}/bin/sunshine-display-toggle off";
          elevated = false;
        }
        {
          do = "true";
          undo = "${sunshineLock}/bin/sunshine-lock";
          elevated = false;
        }
      ];

      systemd.user.services.sunshine.serviceConfig.ExecStopPost =
        "${displayToggle}/bin/sunshine-display-toggle off";
    };
}
