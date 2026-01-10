{ lib, ... }:
let
  inherit (lib) mapAttrsToList flatten;
  top = "60";
  right = "(monitor_w-(window_w)-10)";
  vMid = "((monitor_h*0.5)-(window_h*0.5))";
  notransTag = "notrans";

  windowRulesMap = {
    # Audio Control
    "match:class ^(org.pulseaudio.pavucontrol)$" = [
      "min_size 700 420"
      "size (monitor_w*0.3) (monitor_h*0.33)"
      "move ${right} ${top}"
      "float on"
      "pin on"
      "animation slide top 20%"
    ];

    # Local Send (File Sharing)
    "match:class ^(localsend_app)$" = [
      "move ${right} ${vMid}"
      "size (monitor_w*0.2) (monitor_h*0.8)"
      "float on"
      "pin on"
      "animation slide right 20%"
    ];

    # Airplay
    "match:class ^(GStreamer)$" =
      let
        scale = "0.21";
        ratio = "2.14";
      in
      [
        "move ${right} ${vMid}"
        "size (monitor_w*${scale}) (${ratio}*monitor_w*${scale})"
        "pin on"
        "float on"
        "opacity 1.0 override 1.0 override"
        "no_blur on"
        "animation slide right 20%"
        "keep_aspect_ratio true"
      ];

    # Bluetooth
    "match:class ^(blueberry.py)$" = [
      "move ${right} ${top}"
      "size (monitor_w*0.25) (monitor_h*0.45)"
      "min_size 540 640"
      "float on"
      "pin on"
      "animation slide top 20%"
    ];

    # float
    "float true" = [
      "match:class file_progress"
      "match:class confirm"
      "match:class dialog"
      "match:class download"
      "match:class notification"
      "match:class error"
      "match:class splash"
      "match:class confirmreset"
      "match:class file-roller"
      "match:class ^(it.mijorus.smile)"
      "match:class ^(xdg-desktop-portal-gtk)$"
      "match:class ^(vesktop)$, match:title ^(Discord Popout)$"
      "match:title (Open File)"
      "match:title branchdialog"
      "match:title wlogout"
      "match:title ^(Media viewer)$"
      "match:title ^(File Operation Progress)$"
      "match:title ^(Picture-in-Picture)$"
    ];

    # Fullscreen
    "fullscreen true" = [
      "match:title wlogout"
      "match:initial_class ^(cs2)$"
    ];

    # Disable Tansparent
    "match:tag ${notransTag}" = [
      "opacity 1.0 override 1.0 override"
      "no_blur true"
    ];

    # Steam
    "match:class ^(steam)$" = [
      "workspace unset, match:float true"
      "workspace 7 silent"
      "float true, match:title ^(Friends List)$"
      "float true, match:title ^(Steam Settings)$"
      "center true, match:float true"
    ];
  };

  windowRules = flatten (
    mapAttrsToList (name: values: (map (value: "${name}, ${value}") values)) windowRulesMap
  );
in
{
  wayland.windowManager.hyprland.settings = {
    windowrule = [
      "match:class ^(org.fcitx.), pseudo true"
      # Zen browser
      "opacity 0.9999 override, match:initial_class ^(zen)(.*)"
      # Ghostty
      "opacity 0.9999 override, match:initial_class ^(com.mitchellh.ghostty)$"
      # Picture in picture windows
      "pin true, match:title ^(Picture-in-Picture)$"
      "pin true, match:class ^(vesktop)$, match:title ^(Discord Popout)$"
      # steam game
      "workspace 7 silent, match:class ^(steam_app_)(.*)"
      "fullscreen true, match:class ^(steam_app_)(.*)"
      # VLC
      "workspace 3, match:initial_class ^(vlc), match:float false"
      # discord
      "workspace 4 silent, match:initial_class ^(discord), match:float false"
      # Davinci resolve
      "center 1, match:initial_class ^(resolve), match:float true"
    ]
    ++ windowRules;

    layerrule =
      let
        matchPrefix = "match:namespace";
      in
      map (value: "${matchPrefix} ${value}") [
        "waybar, blur on"
        "logout_dialog, blur on"
        "rofi, blur on"
        "rofi, ignore_alpha 0"
        "swaync-control-center, blur on"
        "swaync-notification-window, blur on"
        "swaync-control-center, ignore_alpha 0"
        "swaync-notification-window, ignore_alpha 0"
        "swaync-control-center, ignore_alpha 0.1"
        "swaync-notification-window, ignore_alpha 0.1"
      ];
  };
}
