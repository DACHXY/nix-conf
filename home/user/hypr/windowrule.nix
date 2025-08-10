let
  inherit (builtins) map concatLists;
  top = "60";
  right = "100%-w-10";
  notransTag = "notrans";
  noTransList = [
    "title:(.*)( - YouTube — Mozilla Firefox)"
    "title:(.*)( - 巴哈姆特動畫瘋 — Mozilla Firefox)"
  ];
in
{
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

    # Airplay
    "move ${right} 10%, class: ^(GStreamer)$"
    "size 21% 80%, class: ^(GStreamer)$"

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
    "pin, class: ^(GStreamer)$"
    "float, class: ^(GStreamer)$"
    "opacity 1.0 override 1.0 override, class: ^(GStreamer)$"
    "animation slide right 20%, class: ^(GStreamer)$"

    # Bluetooth
    "float, class: ^(blueberry.py)$"
    "pin, class: ^(blueberry.py)$"
    "animation slide top 20%, class: ^(blueberry.py)$"

    # Steam
    "workspace: 7 silent, class: ^(steam)$"
    "workspace: unset, class: ^(steam)$, floating: 1"

    # steam game
    "workspace: 7 silent, class: ^(steam_app_)(.*)"

    # Line
    "workspace: 2, initialTitle: ^(LINE)$"
    "float, initialTitle: ^(LINE)$"

    # VLC
    "workspace: 3, initialClass: ^(vlc), floating: 0"

    # discord
    "workspace: 4 silent, initialClass: ^(discord), floating: 0"

    # Davinci resolve
    "center 1, initialClass: ^(resolve), floating: 1"

    # Disable Tansparent for youtube video
    "opacity 1.0 override 1.0 override, title:(.*)( - YouTube — Mozilla Firefox)"
    "noblur, title:(.*)( - YouTube — Mozilla Firefox)"

    "opacity 1.0 override 1.0 override, title:(.*)( - 巴哈姆特動畫瘋 — Mozilla Firefox)"
    "noblur, title:(.*)( - YouTube — Mozilla Firefox)"

    # Disable Tansparent
    "opacity 1.0 override 1.0 override, tag:${notransTag}"
    "noblur, tag: ^(${notransTag})$"
  ]
  ++ (concatLists (
    map (w: [
      "opacity 1.0 override 1.0 override, ${w}"
      "noblur, ${w}"
    ]) noTransList
  ));

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
}
