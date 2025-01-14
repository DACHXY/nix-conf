{
  pkgs,
  terminal,
  xcursor-size,
  ...
}:
let
  swayncScript = pkgs.pkgs.writeShellScriptBin "swaync-start" ''
    #!/usr/bin/env bash
    XDG_CONFIG_HOME="$HOME/.dummy" # Prevent swaync use default gtk theme
    swaync -c "$HOME/.config/swaync/config.json" -s "$HOME/.config/swaync/style.css"
  '';

  startupScript = pkgs.pkgs.writeShellScriptBin "start" ''
    # Fix nemo open in terminal
    dconf write /org/cinnamon/desktop/applications/terminal/exec "''\'${terminal}''\'" &
    dconf write /org/cinnamon/desktop/applications/terminal/exec-arg "''\'''\'" &

    dconf write /org/gnome/desktop/interface/cursor-size ${xcursor-size} &

    ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1 &
    ${swayncScript}/bin/swaync-start &
    dbus-update-activation-environment --systemd --all &
    systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP &
    hyprpaper &
    waybar -c ~/.config/waybar/config.json -s ~/.config/waybar/style.css &
    systemctl --user enable --now hypridle.service &
    fcitx5 -rd &
    fcitx5-remote -r &
    hyprsunset -t 3000k
  '';
in
''${startupScript}/bin/start''
