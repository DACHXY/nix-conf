{
  pkgs,
  terminal,
  xcursor-size,
  ...
}:
let
  startupScript = pkgs.writeShellScriptBin "start" ''
    # Fix nemo open in terminal
    dconf write /org/cinnamon/desktop/applications/terminal/exec "''\'${terminal}''\'" &
    dconf write /org/cinnamon/desktop/applications/terminal/exec-arg "''\'''\'" &
    dconf write /org/gnome/desktop/interface/cursor-size ${builtins.toString xcursor-size} &

    dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP &
    dbus-update-activation-environment --systemd --all &
    systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP QT_QPA_PLATFORMTHEME &
  '';
in
''${startupScript}/bin/start''
