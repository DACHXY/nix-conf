{ pkgs, ... }:
pkgs.writeShellScriptBin "goWin" ''
  set -e
  # Re-exec as root so plain `goWin` works. The NOPASSWD rule for this exact
  # path (modules/users/danny/user-command.nix) makes the sudo call silent.
  if [[ $EUID -ne 0 ]]; then
    exec sudo "$0" "$@"
  fi
  ${pkgs.systemd}/bin/bootctl set-oneshot auto-windows
  ${pkgs.systemd}/bin/systemctl reboot
''
