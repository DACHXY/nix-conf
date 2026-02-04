{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) getExe getExe';

  # ==== binary ==== #
  rofi = getExe pkgs.rofi;
  playerctl = getExe pkgs.playerctl;
  wpctl = getExe' pkgs.wireplumber "wpctl";
  brightnessctl = getExe pkgs.brightnessctl;

  brightnessStep = toString 10;
  volumeStep = toString 4;

  rofiWall = import ../../home/scripts/rofiwall.nix { inherit config pkgs; };
  rbwSelector = import ../../home/scripts/rbwSelector.nix { inherit pkgs; };
  toggleWlogout = pkgs.writeShellScript "toggleWlogout" ''
    if ${pkgs.busybox}/bin/pgrep wlogout > /dev/null; then
      ${pkgs.busybox}/bin/pkill wlogout
    else
       ${getExe config.programs.wlogout.package} --protocol layer-shell
    fi
  '';

  cfg = config.wm;
  mod = cfg.keybinds.mod;
  sep = cfg.keybinds.separator;
in
{
  wm = {
    exec-once = /* bash */ ''
      # Fix nemo open in terminal
      dconf write /org/cinnamon/desktop/applications/terminal/exec "''\'${cfg.app.terminal.name}''\'" &
      dconf write /org/cinnamon/desktop/applications/terminal/exec-arg "''\'''\'" &

      # Hint dark theme
      dconf write /org/gnome/desktop/interface/color-scheme '"prefer-dark"' &

      systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP QT_QPA_PLATFORMTHEME &
    '';

    app = {
      terminal = {
        package = config.programs.ghostty.package;
        name = "ghostty";
        run = "ghostty -e";
      };
      browser = {
        package = config.programs.zen-browser.package;
        name = "zen-twilight";
      };
      file-browser = {
        package = config.programs.yazi.pacakge;
        name = "yazi";
      };
    };
    keybinds = {
      spawn-repeat = {
        # ==== Media ==== #
        "XF86AudioPrev" = "${playerctl} previous";
        "XF86AudioNext" = "${playerctl} next";
        "${mod}${sep}CTRL${sep}COMMA" = "${playerctl} previous";
        "${mod}${sep}CTRL${sep}PERIOD" = "${playerctl} next";
        "XF86AudioPlay" = "${playerctl} play-pause";
        "XF86AudioStop" = "${playerctl} stop";
        "XF86AudioMute" = "${wpctl} set-mute @DEFAULT_SINK@ toggle";
        "XF86AudioRaiseVolume" =
          "${wpctl} set-mute @DEFAULT_SINK@ 0 && ${wpctl} set-volume @DEFAULT_SINK@ ${volumeStep}%+";
        "XF86AudioLowerVolume" =
          "${wpctl} set-mute @DEFAULT_SINK@ 0 && ${wpctl} set-volume @DEFAULT_SINK@ ${volumeStep}%-";
        "XF86MonBrightnessDown" = "${brightnessctl} set ${brightnessStep}%-";
        "XF86MonBrightnessUp" = "${brightnessctl} set ${brightnessStep}%+";
      };
      spawn = {
        "${mod}${sep}Return" = "${getExe cfg.app.terminal.package}";
        "${mod}${sep}F" = "${getExe cfg.app.browser.package}";
        "${mod}${sep}E" = "${cfg.app.terminal.run} ${cfg.app.file-browser.name}";
        "${mod}${sep}CTRL${sep}P" = "${rbwSelector}";
        "${mod}${sep}CTRL${sep}M" = "${toggleWlogout}";

        # Launcher
        "${mod}${sep}CTRL${sep}W" = "${rofiWall}";
        "ALT${sep}SPACE" = "${rofi} -config config/rofi/apps.rasi -show drun";
        "${mod}${sep}PERIOD" = "${rofi} -modi emoji -show emoji";
        "${mod}${sep}CTRL${sep}C" = "${rofi} -modi calc -show calc -no-show-match -no-sort";
      };
    };
  };
}
