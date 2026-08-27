{ pkgs, ... }:
pkgs.writeShellScriptBin "goWin" ''
  set -e
  ${pkgs.systemd}/bin/bootctl set-oneshot auto-windows
  ${pkgs.systemd}/bin/systemctl reboot
''
