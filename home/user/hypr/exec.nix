{
  pkgs,
  terminal,
  xcursor-size,
  ...
}:
let
  swayncScript = pkgs.pkgs.writeShellScriptBin "swaync-start" ''
    XDG_CONFIG_HOME="$HOME/.dummy" # Prevent swaync use default gtk theme
    swaync -c "$HOME/.config/swaync/config.json" -s "$HOME/.config/swaync/style.css"
  '';

  startupScript = pkgs.pkgs.writeShellScriptBin "start" ''
    # Fix nemo open in terminal
    dconf write /org/cinnamon/desktop/applications/terminal/exec "''\'${terminal}''\'" &
    dconf write /org/cinnamon/desktop/applications/terminal/exec-arg "''\'''\'" &

    dconf write /org/gnome/desktop/interface/cursor-size ${xcursor-size} &

    uwsm app -- ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1 &
    uwsm app -- ${swayncScript}/bin/swaync-start &
    dbus-update-activation-environment --systemd --all &
    systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP &
    uwsm app -- hyprpaper &
    uwsm app -- waybar -c ~/.config/waybar/config.json -s ~/.config/waybar/style.css &
    systemctl --user enable --now hypridle.service &
    uwsm fcitx5 -rd &
    uwsm app -- fcitx5-remote -r &
    uwsm app -- hyprsunset -t 3000k
  '';
in
''${startupScript}/bin/start''
