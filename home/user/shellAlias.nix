{ hostname }:
{
  ls = "exa --icons";
  lp = "exa"; # Pure output
  cat = "bat";
  g = "git";
  t = "tmux";

  # Nixos
  rebuild = "sudo nixos-rebuild switch --flake /etc/nixos#${hostname}";
  fullClean = "sudo nix store gc && sudo nix-collect-garbage -d && sudo /run/current-system/bin/switch-to-configuration boot";

  # Hyprland
  hyprlog = "grep -v \"arranged\" $XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/hyprland.log | cat";

  # Systemd Boot
  setWin = "sudo bootctl set-oneshot auto-windows";
  goWin = "sudo bootctl set-oneshot auto-windows && reboot";
  goBios = "sudo bootctl set-oneshot auto-reboot-to-firmware-setup && reboot";

  # TTY
  hideTTY = ''sudo sh -c "echo 0 > /sys/class/graphics/fb0/blank"'';
  showTTY = ''sudo sh -c "echo 1 > /sys/class/graphics/fb0/blank"'';

  # Recover from hyprlock corruption
  letMeIn = ''hyprctl --instance 0 "keyword misc:allow_session_lock_restore 1" && hyprctl --instance 0 dispatch "exec hyprlock"'';
}
