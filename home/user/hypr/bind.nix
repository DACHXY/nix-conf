{
  mainMod,
  config,
  nvidia-offload-enabled,
  lib,
  pkgs,
  monitors ? [ ],
}:
with builtins;
let
  inherit (lib) optionalString;

  notransTag = "notrans";

  browser-bin = "zen";
  prefix = if nvidia-offload-enabled then "nvidia-offload " else "";
  browser = "${prefix}${browser-bin}";
  terminal = "${prefix}ghostty";
  filemanager = "${terminal} -e yazi";

  screenshotFolder = "--output-folder ~/Pictures/Screenshots";
  clipboardOnly = "${screenshotFolder}";

  gamingWorkspace = 7;

  toggleWlogout = pkgs.writeShellScript "toggle" ''
    if ${pkgs.busybox}/bin/pgrep wlogout > /dev/null; then
      ${pkgs.busybox}/bin/pkill wlogout
    else
       ${config.programs.wlogout.package}/bin/wlogout --protocol layer-shell
    fi
  '';

  rofiWall = import ../../scripts/rofiwall.nix { inherit config pkgs; };

  rbwSelector = import ../../scripts/rbwSelector.nix { inherit pkgs; };

  scrollStep =
    let
      monitorsNum = length monitors;
    in
    toString (if (monitorsNum == 0) then 1 else monitorsNum);
in
[
  ''${mainMod}, F, exec, ${browser}''
  ''${mainMod}, RETURN, exec, ${terminal}''
  ''CTRL ALT, T, exec, ${terminal}''
  ''${mainMod}, Q, killactive, ''

  ''${mainMod}, M, exec, ${toggleWlogout}''
  ''${mainMod}, E, exec, ${filemanager}''
  ''${mainMod}, V, togglefloating, ''
  ''ALT, SPACE, exec, rofi -config ~/.config/rofi/apps.rasi -show drun''
  ''${mainMod}, W, exec, ${rofiWall}''
  ''${mainMod}, P, pseudo, # dwindle''
  ''${mainMod}, S, togglesplit, # dwindle''
  ''CTRL ${mainMod} SHIFT, L, exec, hyprlock''

  # Toggle transparent
  ''${mainMod}, n, tagwindow, ${notransTag}''

  # Bitwarden Selector
  ''CTRL ${mainMod}, P, exec, ${rbwSelector}''

  # Screenshot
  ''${mainMod} SHIFT, s, exec, hyprshot -m region ${clipboardOnly}''
  ''CTRL SHIFT, s, exec, hyprshot -m window ${clipboardOnly}''
  ''CTRL SHIFT ${mainMod}, s, exec, hyprshot -m output ${clipboardOnly}''
  ''CTRL ALT, s, exec, hyprshot -m active -m window ${clipboardOnly}''

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

  ''${mainMod}, mouse_down, workspace, e-${scrollStep}''
  ''${mainMod}, mouse_up, workspace, e+${scrollStep}''

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

  ''${mainMod}, G, workspace, ${toString gamingWorkspace}''
  ''${mainMod} SHIFT, G, movetoworkspace, ${toString gamingWorkspace}''
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
