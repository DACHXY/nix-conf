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

      modeWidth = mode: lib.toInt (builtins.head (builtins.match "([0-9]+)x.*" mode));
      positionX = pos: lib.toInt (builtins.head (builtins.match "([0-9]+),.*" pos));
      rightEdge = lib.foldl' (
        acc: o: lib.max acc (positionX o.position + modeWidth o.mode)
      ) 0 physicalOutputs;

      virtualOutput = {
        criteria = "DP-2";
        mode = "1920x1080@60Hz";
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
          pkgs.kanshi
          config.programs.niri.package
        ];
        text = ''
          case "''${1:-}" in
            on)
              kanshictl reload || true
              kanshictl switch ${streamProfile.profile.name}
              ;;
            off)
              ${physicalOnCmds}
              niri msg output ${virtualOutput.criteria} off
              kanshictl reload || true
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
      ];

      systemd.user.services.sunshine.serviceConfig.ExecStopPost =
        "${displayToggle}/bin/sunshine-display-toggle off";
    };
}
