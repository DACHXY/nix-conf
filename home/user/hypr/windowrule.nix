{ ... }:
let
  top = "60";
  right = "100%-w-10";
  notransTag = "notrans";
in
{
  wayland.windowManager.hyprland.settings = {
    windowrule = [
      "match:class ^(org.fcitx.), pseudo true"
      "match:class file_progress, float true"
      "match:class confirm, float true"
      "match:class dialog, float true"
      "match:class download, float true"
      "match:class notification, float true"
      "match:class error, float true"
      "match:class splash, float true"
      "match:class confirmreset, float true"
      "match:title Open File, float true"
      "match:title branchdialog, float true"
      "match:class pavucontrol-qt, float true"
      "match:class pavucontrol, float true"
      "match:class file-roller, float true"
      "match:title wlogout, fullscreen true"
      "match:title wlogout, float true"
      "match:title wlogout, fullscreen true"

      "match:title ^(Media viewer)$, float true"
      "match:title ^(File Operation Progress)$, float true"
      "match:class ^(it.mijorus.smile), float true"
      "match:class ^(xdg-desktop-portal-gtk)$, float true"
      "match:title ^(Steam Settings)$, float true"

      "fullscreen true, match:initial_class ^(cs2)$"

      # Zen browser
      "opacity 0.9999 override, match:initial_class ^(zen)(.*)"

      # Ghostty
      "opacity 0.9999 override, match:initial_class ^(com.mitchellh.ghostty)$"

      # Picture in picture windows
      "float true, match:title ^(Picture-in-Picture)$"
      "pin true, match:title ^(Picture-in-Picture)$"
      "float true, match:class ^(vesktop)$, match:title ^(Discord Popout)$"
      "pin true, match:class ^(vesktop)$, match:title ^(Discord Popout)$"
      "float true, match:class ^(steam)$, match:title ^(Friends List)$"

      # Meidia control
      "move ${right} ${top}, match:class ^(org.pulseaudio.pavucontrol)$"
      "size 30% 33%, match:class ^(org.pulseaudio.pavucontrol)$"

      # Local Send (File Sharing)
      "move ${right} 8%, match:class ^(localsend_app)$"
      "size 20% 80%, match:class ^(localsend_app)$"

      # Bluetooth
      "move ${right} ${top}, match:class ^(blueberry.py)$"
      "size 25% 45%, match:class ^(blueberry.py)$"

      # Media Control
      "float true, match:class ^(org.pulseaudio.pavucontrol)$"
      "pin true, match:class ^(org.pulseaudio.pavucontrol)$"
      "animation slide top 20%, match:class ^(org.pulseaudio.pavucontrol)$"

      # Local Send (File Sharing)
      "float true, match:class ^(localsend_app)$"
      "pin true, match:class ^(localsend_app)$"
      "animation slide right 20%, match:class ^(localsend_app)$"

      # Airplay
      "move ${right} 10%, match:class ^(GStreamer)$"
      "size 21% 80%, match:class ^(GStreamer)$"
      "pin true, match:class ^(GStreamer)$"
      "float true, match:class ^(GStreamer)$"
      "opacity 1.0 override 1.0 override, match:class ^(GStreamer)$"
      "no_blur true, match:class ^(GStreamer)$"
      "animation slide right 20%, match:class ^(GStreamer)$"
      "keep_aspect_ratio true, match:class ^(GStreamer)$"

      # Bluetooth
      "float true, match:class ^(blueberry.py)$"
      "pin true, match:class ^(blueberry.py)$"
      "animation slide top 20%, match:class ^(blueberry.py)$"

      # Steam
      "workspace 7 silent, match:class ^(steam)$"
      "workspace unset, match:class ^(steam)$, match:float true"

      # steam game
      "workspace 7 silent, match:class ^(steam_app_)(.*)"

      # VLC
      "workspace 3, match:initial_class ^(vlc), match:float false"

      # discord
      "workspace 4 silent, match:initial_class ^(discord), match:float false"

      # Davinci resolve
      "center 1, match:initial_class ^(resolve), match:float true"

      # Disable Tansparent
      "opacity 1.0 override 1.0 override, match:tag ${notransTag}"
      "no_blur true, match:tag ^(${notransTag})$"
    ];

    layerrule = [
      "match:namespace waybar, blur on"
      "match:namespace logout_dialog, blur on"
      "match:namespace rofi, blur on"
      "match:namespace rofi, ignore_alpha 0"
      "match:namespace swaync-control-center, blur on"
      "match:namespace swaync-notification-window, blur on"
      "match:namespace swaync-control-center, ignore_alpha 0"
      "match:namespace swaync-notification-window, ignore_alpha 0"
      "match:namespace swaync-control-center, ignore_alpha 0.1"
      "match:namespace swaync-notification-window, ignore_alpha 0.1"
    ];
  };
}
