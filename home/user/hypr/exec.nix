{ pkgs, lib, inputs, system, ... }:
let
  startupScript = pkgs.pkgs.writeShellScriptBin "start" ''
    swaync -s ~/.config/swaync/style.css -c ~/.config/swaync/config.json &
    dbus-update-activation-environment --systemd --all &
    systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP &
    waybar -c ~/.config/waybar/config.json -s ~/.config/waybar/style.css &
    swayidle -w &
    sway-audio-idle-inhibit &
    fcitx5 -d -r &
    fcitx5-remote -r &
    hyprsunset -t 3000k &
  '';
in
''${startupScript}/bin/start''
