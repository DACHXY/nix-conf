{
  config,
  inputs,
  lib,
  ...
}:
let
  inherit (lib)
    concatMapStrings
    concatStrings
    getExe
    mkIf
    ;

  # ── Sources whose system audio can be streamed to the Mac ───────────────────
  # ip   = the host's netbird address (stable per peer)
  # port = UDP port the host sends RTP to. The receiver (ffmpeg's SDP/RTP
  #        demuxer) also binds RTP+1 for RTCP, so ports must be at least 2
  #        apart — 46000/46001 would collide (cscc's RTCP == workstation's RTP).
  sources = [
    {
      host = "dn-cscc";
      ip = "100.104.150.125";
      port = 46000;
    }
    {
      host = "dn-workstation";
      ip = "100.104.154.131";
      port = 46010;
    }
  ];

  # dn-notebook — the Mac. Never changes, so it is not in `sources`.
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

  # Rendered in pure eval (no derivation) so the text is inspectable and
  # shellcheck-able without building for aarch64-darwin.
  pluginText =
    pkgs:
    builtins.replaceStrings
      [ "@mpv@" "@hosts@" "@vars@" ]
      [
        (getExe pkgs.mpv)
        (concatMapStrings (s: " '${s.host}'") sources)
        (concatStrings (
          map (s: ''
            ${lib.replaceStrings [ "-" ] [ "_" ] s.host}_ip='${s.ip}'
            ${lib.replaceStrings [ "-" ] [ "_" ] s.host}_port='${toString s.port}'
          '') sources
        ))
      ]
      (builtins.readFile ./audio-rtp/${pluginName});
in
{
  # ── Sender: a listed host streams its default sink monitor over RTP ────────
  flake.modules.nixos.audio-rtp =
    {
      config,
      lib,
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

  # ── Receiver: SwiftBar plugin on the Mac picks which source to listen to ──
  flake.modules.darwin.gui =
    {
      pkgs,
      config,
      ...
    }:
    let
      user = config.my.user.name;

      # Built from the ~/projects/iaudio flake (input `iaudio`) with the
      # system Swift toolchain — nixpkgs' swift cannot link SwiftUI/AppKit.
      iaudio = inputs.iaudio.packages.${pkgs.stdenv.hostPlatform.system}.default;
    in
    {
      environment.systemPackages = [ pkgs.mpv ];

      home-manager.users.${user} = {
        home.file."Documents/swiftbar-plugins/${pluginName}" = {
          executable = true;
          text = pluginText pkgs;
        };

        # IAudio.app reads this.
        home.file."Library/Application Support/iaudio/hosts.json".text = builtins.toJSON {
          mpv = getExe pkgs.mpv;
          hosts = map (s: {
            name = s.host;
            inherit (s) ip port;
          }) sources;
        };

        launchd.agents.iaudio = {
          enable = true;
          config = {
            ProgramArguments = [
              "${iaudio}/Applications/IAudio.app/Contents/MacOS/IAudio"
            ];
            RunAtLoad = true;
          };
        };
      };
    };
}
