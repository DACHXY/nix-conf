{
  lib,
  ...
}:
let
  inherit (lib)
    concatMapStrings
    concatStrings
    getExe
    getExe'
    mkIf
    ;

  sources = [
    {
      host = "dn-cscc";
      port = 46000;
    }
    {
      host = "dn-workstation";
      port = 46001;
    }
  ];

  receiver = "100.104.173.164";

  # Sender side: opus / lowdelay / 10 ms frames. The receiver needs a matching
  # SDP, which the SwiftBar plugin writes out verbatim — payload type, clock
  # rate, channel count and port all have to agree with this.
  senderArgs =
    s:
    "-f pulse -i @DEFAULT_MONITOR@ -ac 2 -ar 48000 "
    + "-c:a libopus -b:a 128k -application lowdelay -frame_duration 10 "
    + "-f rtp rtp://${receiver}:${toString s.port}";

  pluginName = "dn-audio.30s.sh";

  pluginText =
    pkgs:
    builtins.replaceStrings
      [ "@ffplay@" "@hosts@" "@vars@" ]
      [
        (getExe' pkgs.ffmpeg "ffplay")
        (concatMapStrings (s: " '${s.host}'") sources)
        (concatStrings (
          map (s: ''
            ${lib.replaceStrings [ "-" ] [ "_" ] s.host}_port='${toString s.port}'
          '') sources
        ))
      ]
      (builtins.readFile ./audio-rtp/${pluginName});
in
{
  flake.modules.nixos.audio-rtp =
    {
      config,
      pkgs,
      ...
    }:
    let
      mine = builtins.filter (s: s.host == config.networking.hostName) sources;
      s = if mine == [ ] then null else builtins.head mine;
    in
    {
      config = mkIf (s != null) {
        systemd.user.services.dn-audio-rtp = {
          description = "Stream system audio to dn-notebook over RTP/Opus";
          wantedBy = [ "graphical-session.target" ];
          partOf = [ "graphical-session.target" ];
          serviceConfig = {
            ExecStart = "${getExe pkgs.ffmpeg} -hide_banner -loglevel error -nostdin ${senderArgs s}";
            Restart = "always";
            RestartSec = 5;
          };
        };
      };
    };

  flake.modules.darwin.gui =
    {
      pkgs,
      config,
      ...
    }:
    {
      environment.systemPackages = [ pkgs.ffmpeg ];

      home-manager.users.${config.my.user.name}.home.file."Documents/swiftbar-plugins/${pluginName}" = {
        executable = true;
        text = pluginText pkgs;
      };
    };
}
