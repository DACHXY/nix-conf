{ pkgs, ... }:
{
  home.packages = with pkgs; [
    quickshell
  ];

  systemd.user.services.quickshell = {
    Unit = {
      Description = "Quickshell";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      type = "exec";
      ExecStart = "${pkgs.quickshell}/bin/quickshell";
      Restart = "on-failure";
      RestartSec = "5s";
      TimeoutStopSec = "5s";
      Environment = [
        "QT_QPA_PLATFORM=wayland"
      ];

      Slice = "session.slice";
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
