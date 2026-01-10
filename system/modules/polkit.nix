{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    polkit
    polkit_gnome
  ];
  # polkit-gnome execution is handled by Hyprland exec.nix
  # as hyprland do not cooperate with graphical-session.target
  services.gnome.gnome-keyring.enable = true;

  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    enable = true;
    description = "Gnome authentication agent";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session-pre.target" ];
    partOf = [ "graphical-session.target" ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "always";
      RestartSec = 5;
    };
  };
}
