# AirDrop between iPhones and this machine (see github:t4t5/owly).
#
# wlp0s20f3 is an Intel AX211 (8086:7a70), which owly supports only in
# exclusive mode: the radio takes the card over and Wi-Fi is down until the
# session ends. Nothing depends on it here — wired eno1 carries traffic. Intel
# cards are stuck on channel 6, so a 2.4 MB photo takes ~10-17 s.
{ inputs, ... }:
{
  configurations.nixos.dn-cscc.module =
    { config, lib, pkgs, ... }:
    let
      owly = lib.getExe config.services.owly.package;
      # owly-receive needs awdl0 with its fe80 address; at boot it wins the race
      # against owly-radio and exits with "awdl0: ENODEV".
      wait-for-awdl0 = pkgs.writeShellScript "wait-for-awdl0" ''
        until ${lib.getExe' pkgs.iproute2 "ip"} -6 addr show dev awdl0 2>/dev/null | ${lib.getExe pkgs.gnugrep} -q fe80; do
          sleep 1
        done
      '';
      # owly receive prints one received path per line on stdout, so only the
      # journal of this unit can tell AirDrop files apart from ordinary downloads.
      notify-received = pkgs.writeShellScript "owly-notify-received" ''
        ${lib.getExe' pkgs.systemd "journalctl"} -n0 -fu owly-receive -o cat | while IFS= read -r path; do
          [ -f "$path" ] || continue
          ${lib.getExe pkgs.libnotify} -a AirDrop -i folder-download \
            "AirDrop" "Received $(${lib.getExe' pkgs.coreutils "basename"} -- "$path")"
        done
      '';
      # The bar panel's send action: owly-drop <service id> <name>. Asks for the
      # files, then sends them and reports through notifications, since the
      # panel has closed by then.
      owly-drop = pkgs.writeShellApplication {
        name = "owly-drop";
        runtimeInputs = [
          pkgs.zenity
          pkgs.libnotify
        ];
        text = ''
          id=$1
          name=''${2:-$1}
          mapfile -t files < <(zenity --file-selection --multiple --separator=$'\n' \
            --title="AirDrop to $name") || exit 0
          [ "''${#files[@]}" -gt 0 ] || exit 0

          notify-send -a AirDrop "AirDrop" "Sending ''${#files[@]} file(s) to $name…"
          if out=$(${owly} send --to "$id" -- "''${files[@]}" 2>&1); then
            notify-send -a AirDrop "AirDrop" "Sent to $name"
          else
            notify-send -a AirDrop -u critical "AirDrop failed" "$(tail -n 3 <<<"$out")"
          fi
        '';
      };
    in
    {
      imports = [ inputs.owly.nixosModules.default ];

      services.owly.enable = true;

      # owly adds an IPv6 link-local address to its awdl0 tap; the kernel answers
      # -EACCES ("IPv6 is disabled on this device") for any interface created with
      # IPv6 off, which is what modules/networking/networkmanager.nix sets globally.
      # Only newly created interfaces are re-enabled: eno1/wg0/tun0 keep their state.
      boot.kernel.sysctl."net.ipv6.conf.default.disable_ipv6" = lib.mkForce 0;

      # Kept on, so the phone always sees this machine in AirDrop. owlyd only
      # lends the card to a lease holder, so one service holds the lease and
      # another announces and takes the files.
      #
      # --accept takes anything from anyone within radio range, which is the
      # price of answering while nobody is at the terminal (without it the
      # prompt reads stdin and declines after 15 s). To pause AirDrop:
      # systemctl stop owly-radio owly-receive
      security.polkit.extraConfig = ''
        /* A service has no seat, so owlyd's allow_active rule does not cover
           `owly radio up`; this lets danny take the radio from a unit. */
        polkit.addRule(function(action, subject) {
          if (action.id == "io.github.t4t5.Owly.acquire" && subject.user == "danny") {
            return polkit.Result.YES;
          }
        });

        /* The bar widget toggles the units without a terminal. Limit that to
           start/stop of these two units, not arbitrary systemd changes. */
        polkit.addRule(function(action, subject) {
          if (action.id == "org.freedesktop.systemd1.manage-units" &&
              subject.user == "danny" &&
              (action.lookup("unit") == "owly-radio.service" ||
               action.lookup("unit") == "owly-receive.service") &&
              (action.lookup("verb") == "start" || action.lookup("verb") == "stop")) {
            return polkit.Result.YES;
          }
        });
      '';

      systemd.services.owly-radio = {
        description = "Hold the Wi-Fi radio for AirDrop";
        after = [ "owlyd.service" ];
        wants = [ "owlyd.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          User = "danny";
          ExecStart = "${owly} radio up";
          Restart = "always";
          RestartSec = "10s";
        };
      };

      # dn-cscc-only additions: the bar widget and its notification service.
      home-manager.users.${config.my.user.name} = {
        home.packages = [ owly-drop ];

        # A fixed path rather than the store path: once the settings UI touches
        # [plugins], noctalia copies the sources into its own settings.toml, and
        # a store path there would pin the plugin at that build.
        xdg.dataFile."noctalia/owly-plugin".source = ./owly-plugin;

        programs.noctalia.settings = {
          plugins.enabled = lib.mkAfter [ "dachxy/owly" ];
          plugins.source = lib.mkAfter [
            {
              kind = "path";
              location = "${config.home-manager.users.${config.my.user.name}.xdg.dataHome}/noctalia/owly-plugin";
              name = "owly";
            }
          ];
          widget.airdrop.type = "dachxy/owly:airdrop";
          bar.default.end = lib.mkAfter [ "airdrop" ];
        };

        systemd.user.services.owly-notify = {
          Unit.Description = "Notify when owly receives an AirDrop file";
          Install.WantedBy = [ "default.target" ];
          Service = {
            ExecStart = "${notify-received}";
            Restart = "always";
            RestartSec = 5;
          };
        };
      };

      systemd.services.owly-receive = {
        description = "Receive AirDrop files";
        after = [ "owly-radio.service" ];
        wants = [ "owly-radio.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          User = "danny";
          ExecStartPre = wait-for-awdl0;
          ExecStart = "${owly} receive --accept --dir /home/danny/Downloads";
          Restart = "always";
          RestartSec = "10s";
        };
      };
    };
}
