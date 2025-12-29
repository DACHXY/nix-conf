{
  osConfig,
  config,
  pkgs,
  ...
}:
let
  hostname = osConfig.networking.hostName;

  shouldNotify =
    (builtins.hasAttr "ntfy-client" config.services) && config.services.ntfy-client.enable;

  rebuildCommand = ''
    sudo nixos-rebuild switch --target-host "$TARGET" \
      --build-host "$BUILD" \
      --sudo --ask-sudo-password $@'';

  rebuild = pkgs.writeShellScriptBin "rebuild" ''
    ${rebuildCommand}
  '';

  # Notification
  nrebuild = pkgs.writeShellScriptBin "nrebuild" ''
    ${
      if shouldNotify then
        ''
          export NTFY_TITLE="🎯 ${hostname}" 
          export NTFY_TAGS="gear"

          if ${rebuildCommand}
          then
            ntfy pub system-build "✅ Build success" > /dev/null 2>&1
          else
            ntfy pub system-build "⛔ Build failed" > /dev/null 2>&1
          fi
        ''
      else
        rebuildCommand
    }
  '';
in
{
  home.packages = [
    nrebuild
    rebuild
  ];

  programs.fish.shellAliases = {
    ls = "exa --icons";
    lp = "exa"; # Pure output
    cat = "bat";
    g = "git";
    t = "tmux";
    podt = "podman-tui";

    # Nixos
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
  };
}
