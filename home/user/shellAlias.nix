{
  ls = "exa";
  cat = "bat";
  y = "yazi";
  g = "git";
  cd = "z"; # Zoxide
  t = "tmux";
  vim = "nvim";
  vi = "nvim";

  # Nixos
  rebuild = "sudo nixos-rebuild switch --flake /etc/nixos";
  fullClean = "nix-collect-garbage --delete-old && sudo nix-collect-garbage -d && sudo /run/current-system/bin/switch-to-configuration boot";

  # Systemd Boot
  setWin = "sudo bootctl set-oneshot auto-windows";
  goWin = "sudo bootctl set-oneshot auto-windows && reboot";
  goBios = "sudo bootctl set-onshot auto-reboot-to-firmware-setup && reboot";
}
