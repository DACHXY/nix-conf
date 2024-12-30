{ mainMod }:
let
  uwsm = "uwsm app --";
  browser = "firefox";
  terminal = "ghostty";
  filemanager = "thunar";
  scripts = "~/.config/scripts";

  resizeStep = builtins.toString 20;
  brightnessStep = builtins.toString 10;
  volumeStep = builtins.toString 2;
in
[
  ''${mainMod}, F, exec, ${browser}''
  ''${mainMod}, RETURN, exec, ${terminal}''
  ''CTRL ALT, T, exec, ${terminal}''
  ''${mainMod}, Q, killactive, ''

  ''${mainMod}, M, exec, wlogout --protocol layer-shell''
  ''${mainMod}, E, exec, ${filemanager}''
  ''${mainMod}, V, togglefloating, ''
  ''ALT, SPACE, exec, rofi -config ~/.config/rofi/apps.rasi -show drun''
  ''${mainMod} ALT, W, exec, ${uwsm} ${scripts}/waybarRestart.sh''
  ''${mainMod}, P, pseudo, # dwindle''
  ''${mainMod}, S, togglesplit, # dwindle''
  ''CTRL ${mainMod} SHIFT, L, exec, swaylock''
  ''${mainMod} SHIFT, s, exec, hyprshot -m region --clipboard-only --freeze''
  ''CTRL SHIFT, s, exec, hyprshot -m window --clipboard-only --freeze''
  ''CTRL SHIFT ${mainMod}, s, exec, hyprshot -m output --clipboard-only --freeze''
  ''${mainMod}, PERIOD, exec, flatpak run it.mijorus.smile ''
  ''${mainMod}, X, exec, sleep 0.1 && swaync-client -t -sw''
  ''${mainMod} SHIFT, C, centerwindow''
  '',F11, fullscreen''
  ''${mainMod}, C, exec, code''

  # Cycle windows
  ''ALT, TAB, cyclenext''
  ''ALT, TAB, bringactivetotop''

  ''${mainMod}, h, movefocus, l''
  ''${mainMod}, l, movefocus, r''
  ''${mainMod}, k, movefocus, u''
  ''${mainMod}, j, movefocus, d''

  ''${mainMod}, mouse_down, workspace, e-1''
  ''${mainMod}, mouse_up, workspace, e+1''

  ''${mainMod} CTRL, l, resizeactive, ${resizeStep} 0''
  ''${mainMod} CTRL, h, resizeactive, -${resizeStep} 0''
  ''${mainMod} CTRL, k, resizeactive, 0 -${resizeStep}''
  ''${mainMod} CTRL, j, resizeactive, 0 ${resizeStep}''

  ''${mainMod} SHIFT, l, movewindow, r''
  ''${mainMod} SHIFT, h, movewindow, l''
  ''${mainMod} SHIFT, k, movewindow, u''
  ''${mainMod} SHIFT, j, movewindow, d''


  # Media
  '',XF86AudioRaiseVolume, exec, wpctl set-mute @DEFAULT_SINK@ 0 && wpctl set-volume @DEFAULT_SINK@ ${volumeStep}%+''
  '',XF86AudioLowerVolume, exec, wpctl set-mute @DEFAULT_SINK@ 0 && wpctl set-volume @DEFAULT_SINK@ ${volumeStep}%-''
  '',XF86MonBrightnessDown, exec, brightnessctl set ${brightnessStep}%-''
  '',XF86MonBrightnessUp, exec, brightnessctl set ${brightnessStep}%+''
  '',XF86AudioPrev, exec, playerctl previous''
  '',XF86AudioNext, exec, playerctl next''
  '',XF86AudioPlay, exec, playerctl play-pause''
  '',XF86AudioStop, exec, playerctl stop''
  '',XF86AudioMute, exec, wpctl set-mute @DEFAULT_SINK@ toggle''

  # ==== Plugins ==== #
  # Overview
  ''${mainMod}, o, hyprexpo:expo, toggle''
] ++ (
  # workspaces
  # binds $mainMod + [shift +] {1..9} to [move to] workspace {1..9}
  builtins.concatLists (builtins.genList
    (i:
      let ws = i + 1;
      in
      [
        "${mainMod}, code:1${toString i}, workspace, ${toString ws}"
        "${mainMod} SHIFT, code:1${toString i}, movetoworkspace, ${toString ws}"
      ]
    )
    9)
)

