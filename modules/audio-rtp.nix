{
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
  # metaPort = TCP port for the "now playing" HTTP endpoint (see
  #        audio-rtp/nowplaying.py). Only that interface's firewall is opened.
  sources = [
    {
      host = "dn-cscc";
      ip = "100.104.150.125";
      port = 46000;
      metaPort = 46002;
    }
    {
      host = "dn-workstation";
      ip = "100.104.154.131";
      port = 46010;
      metaPort = 46012;
    }
  ];

  # dn-notebook — the Mac. Never changes, so it is not in `sources`.
  receiver = "100.104.173.164";

  # Dedicated virtual sink, shared by the PipeWire object and the ffmpeg input
  # below. Nothing reaches it unless the user routes audio there (see the
  # PipeWire block), so the RTP stream carries silence until then.
  sinkName = "dn-audio-rtp";

  # Sender side: opus / lowdelay / 10 ms frames. The receiver needs a matching
  # SDP, which the SwiftBar plugin writes out verbatim — payload type, clock
  # rate, channel count and port all have to agree with this.
  senderArgs =
    s:
    "-f pulse -i ${sinkName}.monitor -ac 2 -ar 48000 "
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
  # ── Sender: a listed host streams the "dn-notebook (RTP)" sink over RTP ────
  # Pick that sink as the default output (or route a single app to it) in
  # noctalia / pavucontrol to hear the audio on the Mac; switch back to the
  # speakers to stop. A null sink of our own instead of @DEFAULT_MONITOR@ is
  # what makes the choice explicit — Sunshine does the same with its
  # sink-sunshine-stereo.
  flake.modules.nixos.audio-rtp =
    {
      config,
      pkgs,
      ...
    }:
    let
      mine = builtins.filter (s: s.host == config.networking.hostName) sources;
      s = if mine == [ ] then null else builtins.head mine;

      # ThreadingHTTPServer + playerctl + magick; the script itself is pure
      # python stdlib (./audio-rtp/nowplaying.py).
      nowplaying = pkgs.writeShellApplication {
        name = "dn-audio-nowplaying";
        runtimeInputs = [
          pkgs.playerctl
          pkgs.imagemagick
        ];
        text = ''
          exec ${pkgs.python3}/bin/python3 ${./audio-rtp/nowplaying.py} "$@"
        '';
      };
    in
    {
      config = mkIf (s != null) {
        # Dedicated sink whose monitor ffmpeg captures. session/driver priority
        # 0 keeps wireplumber from making it the default output at boot — the
        # real hardware sink stays preferred.
        services.pipewire.extraConfig.pipewire."90-dn-audio-rtp" = {
          "context.objects" = [
            {
              factory = "adapter";
              args = {
                "factory.name" = "support.null-audio-sink";
                "node.name" = sinkName;
                "node.description" = "dn-notebook (RTP)";
                "media.class" = "Audio/Sink";
                "audio.position" = [
                  "FL"
                  "FR"
                ];
                "audio.rate" = 48000;
                "object.linger" = true;
                # sink volume must be applied to the monitor, i.e. to what the
                # Mac receives.
                "monitor.channel-volumes" = true;
                "priority.session" = 0;
                "priority.driver" = 0;
              };
            }
          ];
        };

        systemd.user.services.dn-audio-rtp = {
          description = "Stream dn-audio-rtp sink to dn-notebook over RTP/Opus";
          wantedBy = [ "graphical-session.target" ];
          partOf = [ "graphical-session.target" ];
          # The sink lives in pipewire-pulse; start after it so ffmpeg's pulse
          # source exists on the first try (Restart=always is only a fallback).
          after = [ "pipewire-pulse.service" ];
          wants = [ "pipewire-pulse.service" ];
          serviceConfig = {
            ExecStart = "${getExe pkgs.ffmpeg} -hide_banner -loglevel error -nostdin ${senderArgs s}";
            Restart = "always";
            RestartSec = 5;
          };
        };

        # Now Playing metadata for the Mac's IAudio.app: playerctl snapshot,
        # cover art and remote controls on metaPort. Plain HTTP, reachable only
        # over netbird (firewall rule below).
        systemd.user.services.dn-audio-nowplaying = {
          description = "Serve now-playing metadata for dn-audio-rtp";
          wantedBy = [ "graphical-session.target" ];
          partOf = [ "graphical-session.target" ];
          serviceConfig = {
            ExecStart = "${nowplaying}/bin/dn-audio-nowplaying --port ${toString s.metaPort}";
            Restart = "always";
            RestartSec = 5;
          };
        };

        # No auth, no TLS: only the netbird interface may reach metaPort.
        networking.firewall.interfaces."nb-wt0".allowedTCPPorts = [ s.metaPort ];
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
        # Puts IAudio.app in ~/Applications/Home Manager Apps through
        # targets.darwin.copyApps, which is what makes it visible to Spotlight
        # and Launchpad — the bundle itself lives in the read-only store, which
        # LaunchServices will not index.
        home.packages = [ iaudio ];

        home.file."Documents/swiftbar-plugins/${pluginName}" = {
          executable = true;
          text = pluginText pkgs;
        };

        # IAudio.app reads this.
        home.file."Library/Application Support/iaudio/hosts.json".text = builtins.toJSON {
          mpv = getExe pkgs.mpv;
          hosts = map (s: {
            name = s.host;
            inherit (s) ip port metaPort;
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
