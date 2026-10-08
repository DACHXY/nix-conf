{
  flake.modules.nixos.gui =
    { config, ... }:
    {
      # ydotool synthesises input through /dev/uinput, so it is compositor-agnostic
      # and works on niri/Wayland where xdotool does not. The NixOS module runs
      # ydotoold, exports YDOTOOL_SOCKET=/run/ydotoold/socket and installs ydotool.
      programs.ydotool.enable = true;
      users.users.${config.my.user.name}.extraGroups = [ "ydotool" ];
    };
}
