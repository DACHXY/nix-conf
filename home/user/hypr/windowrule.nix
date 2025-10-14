{ ... }:
let
  top = "60";
  right = "100%-w-10";
  notransTag = "notrans";
in
{
  wayland.windowManager.hyprland.settings = {
    windowrule = [
      "pseudo, class:(org.fcitx.)"
      "float, class:file_progress"
      "float, class:confirm"
      "float, class:dialog"
      "float, class:download"
      "float, class:notification"
      "float, class:error"
      "float, class:splash"
      "float, class:confirmreset"
      "float, title:Open File"
      "float, title:branchdialog"
      "float, class:pavucontrol-qt"
      "float, class:pavucontrol"
      "float, class:file-roller"
      "fullscreen, title:wlogout"
      "float, title:wlogout"
      "fullscreen, title:wlogout"

      "float, title:^(Media viewer)$"
      "float, title:^(File Operation Progress)$"
      "float, class:^(it.mijorus.smile)"
      "float, class:^(xdg-desktop-portal-gtk)$"
      "float, title:^(Steam Settings)$"

      "fullscreen, initialClass:^(cs2)$"

      # Zen browser
      "opacity 0.9999 override, initialClass:^(zen)(.*)"

      # Ghostty
      "opacity 0.9999 override, initialClass:^(com.mitchellh.ghostty)$"

      # Picture in picture windows
      "float, title:^(Picture-in-Picture)$"
      "pin, title:^(Picture-in-Picture)$"
      "float, class:^(vesktop)$,title:^(Discord Popout)$"
      "pin, class:^(vesktop)$,title:^(Discord Popout)$"
      "float, class:^(steam)$,title:^(Friends List)$"

      # Meidia control
      "move ${right} ${top}, class: ^(org.pulseaudio.pavucontrol)$"
      "size 30% 33%, class: ^(org.pulseaudio.pavucontrol)$"

      # Local Send (File Sharing)
      "move ${right} 8%, class: ^(localsend_app)$"
      "size 20% 80%, class: ^(localsend_app)$"

      # Bluetooth
      "move ${right} ${top}, class: ^(blueberry.py)$"
      "size 25% 45%, class: ^(blueberry.py)$"

      # Media Control
      "float, class: ^(org.pulseaudio.pavucontrol)$"
      "pin, class: ^(org.pulseaudio.pavucontrol)$"
      "animation slide top 20%, class: ^(org.pulseaudio.pavucontrol)$"

      # Local Send (File Sharing)
      "float, class: ^(localsend_app)$"
      "pin, class: ^(localsend_app)$"
      "animation slide right 20%, class: ^(localsend_app)$"

      # Airplay
      "move ${right} 10%, class: ^(GStreamer)$"
      "size 21% 80%, class: ^(GStreamer)$"
      "pin, class: ^(GStreamer)$"
      "float, class: ^(GStreamer)$"
      "opacity 1.0 override 1.0 override, class: ^(GStreamer)$"
      "noblur, class: ^(GStreamer)$"
      "animation slide right 20%, class: ^(GStreamer)$"
      "keepaspectratio, class: ^(GStreamer)$"

      # Bluetooth
      "float, class: ^(blueberry.py)$"
      "pin, class: ^(blueberry.py)$"
      "animation slide top 20%, class: ^(blueberry.py)$"

      # Steam
      "workspace 7 silent, class: ^(steam)$"
      "workspace unset, class: ^(steam)$, floating: 1"

      # steam game
      "workspace 7 silent, class: ^(steam_app_)(.*)"

      # VLC
      "workspace 3, initialClass: ^(vlc), floating: 0"

      # discord
      "workspace 4 silent, initialClass: ^(discord), floating: 0"

      # Davinci resolve
      "center 1, initialClass: ^(resolve), floating: 1"

      # Disable Tansparent
      "opacity 1.0 override 1.0 override, tag:${notransTag}"
      "noblur, tag: ^(${notransTag})$"
    ];

    layerrule = [
      "blur, waybar"
      "blur, logout_dialog"
      "unset, rofi"
      "blur, rofi"
      "ignorezero, rofi"
      "unset, swaync-control-center"
      "unset, swaync-notification-window"
      "blur, swaync-control-center"
      "blur, swaync-notification-window"
      "ignorezero, swaync-control-center"
      "ignorezero, swaync-notification-window"
      "ignorealpha 0.1, swaync-control-center"
      "ignorealpha 0.1, swaync-notification-window"
    ];
  };
}
