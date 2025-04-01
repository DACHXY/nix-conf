{
  ls = "exa --icons";
  lp = "exa"; # Pure output
  cat = "bat";
  y = "yazi";
  g = "git";
  t = "tmux";

  # Nixos
  rebuild = "sudo nixos-rebuild switch --flake /etc/nixos";
  fullClean = "sudo nix store gc && sudo /run/current-system/bin/switch-to-configuration boot";

  # Hyprland
  hyprlog = "grep -v \"arranged\" $XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/hyprland.log | cat";
  saveEye = "pkill -f hyprsunset && hyprctl dispatch exec 'hyprsunset -t 3300'";

  # Systemd Boot
  setWin = "sudo bootctl set-oneshot auto-windows";
  goWin = "sudo bootctl set-oneshot auto-windows && reboot";
  goBios = "sudo bootctl set-oneshot auto-reboot-to-firmware-setup && reboot";

  # TTY
  hideTTY = ''sudo sh -c "echo 0 > /sys/class/graphics/fb0/blank"'';
  showTTY = ''sudo sh -c "echo 1 > /sys/class/graphics/fb0/blank"'';
}
