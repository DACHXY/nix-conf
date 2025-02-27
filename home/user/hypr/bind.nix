{ mainMod, nvidia-offload-enabled }:
let
  firefox = "firefox-nightly";
  prefix = if nvidia-offload-enabled then "offload" else "";
  browser = "${prefix} ${firefox}";
  noOffloadBrowser = "${firefox} -P noOffload";
  terminal = "${prefix} ghostty";
  # filemanager = "nemo";
  filemanager = "${terminal} -e yazi";
  scripts = "~/.config/scripts";

  # freezeShot = "--freeze";
  freezeShot = "";
  # clipboard-only = "${clipboardOnly}";
  screenshotFolder = "--output-folder ~/Pictures/Screenshots";
  clipboardOnly = "${screenshotFolder}";
in
[
  ''${mainMod}, F, exec, ${browser}''
  ''CTRL ${mainMod}, F, exec, ${noOffloadBrowser} -no-remote''
  ''${mainMod}, RETURN, exec, ${terminal}''
  ''CTRL ALT, T, exec, ${terminal}''
  ''${mainMod}, Q, killactive, ''

  ''${mainMod}, M, exec, wlogout --protocol layer-shell''
  ''${mainMod}, E, exec, ${filemanager}''
  ''${mainMod}, V, togglefloating, ''
  ''ALT, SPACE, exec, rofi -config ~/.config/rofi/apps.rasi -show drun''
  ''${mainMod} ALT, W, exec, ${scripts}/waybarRestart.sh''
  ''${mainMod}, P, pseudo, # dwindle''
  ''${mainMod}, S, togglesplit, # dwindle''
  ''CTRL ${mainMod} SHIFT, L, exec, hyprlock''

  # Screenshot
  ''${mainMod} SHIFT, s, exec, hyprshot -m region ${clipboardOnly} ${freezeShot}''
  ''CTRL SHIFT, s, exec, hyprshot -m window ${clipboardOnly} ${freezeShot}''
  ''CTRL SHIFT ${mainMod}, s, exec, hyprshot -m output ${clipboardOnly} ${freezeShot}''
  ''CTRL ALT, s, exec, hyprshot -m active -m window ${clipboardOnly} ${freezeShot}''

  ''${mainMod}, PERIOD, exec, rofi -modi emoji -show emoji''
  ''CTRL ${mainMod}, c, exec, rofi -show calc -modi calc -no-show-match -no-sort''
  ''${mainMod}, X, exec, sleep 0.1 && swaync-client -t -sw''
  ''${mainMod} SHIFT, C, centerwindow''
  '',F11, fullscreen''
  ''${mainMod}, C, exec, code''

  # Color Picker
  ''${mainMod} SHIFT, P, exec, hyprpicker -f hex -a -z''

  # Cycle windows
  ''ALT, TAB, cyclenext''
  ''ALT, TAB, bringactivetotop''

  ''${mainMod}, h, movefocus, l''
  ''${mainMod}, l, movefocus, r''
  ''${mainMod}, k, movefocus, u''
  ''${mainMod}, j, movefocus, d''

  ''${mainMod}, mouse_down, workspace, e-1''
  ''${mainMod}, mouse_up, workspace, e+1''

  ''${mainMod} SHIFT, l, movewindow, r''
  ''${mainMod} SHIFT, h, movewindow, l''
  ''${mainMod} SHIFT, k, movewindow, u''
  ''${mainMod} SHIFT, j, movewindow, d''

  # Media
  '',XF86AudioPrev, exec, playerctl previous''
  '',XF86AudioNext, exec, playerctl next''
  ''${mainMod} CTRL, COMMA, exec, playerctl previous''
  ''${mainMod} CTRL, PERIOD, exec, playerctl next''
  '',XF86AudioPlay, exec, playerctl play-pause''
  '',XF86AudioStop, exec, playerctl stop''
  '',XF86AudioMute, exec, wpctl set-mute @DEFAULT_SINK@ toggle''

  # ==== Plugins ==== #
  # Overview
  ''${mainMod}, o, hyprtasking:toggle, cursor''
  ''${mainMod}, TAB, hyprtasking:toggle, all''
]
++ (
  # workspaces
  # binds $mainMod + [shift +] {1..9} to [move to] workspace {1..9}
  builtins.concatLists (
    builtins.genList (
      i:
      let
        ws = i + 1;
      in
      [
        "${mainMod}, code:1${toString i}, workspace, ${toString ws}"
        "${mainMod} SHIFT, code:1${toString i}, movetoworkspace, ${toString ws}"
      ]
    ) 9
  )
)
