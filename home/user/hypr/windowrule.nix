{
  windowrule = [
    "pseudo, class:fcitx"
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
    "idleinhibit stayfocused, class:mpv"
  ];

  windowrulev2 = [
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

    # Steam
    "workspace: 5 silent, class: ^(steam)$"
    "workspace: unset, class: ^(steam)$, floating: 1"

    # Line
    "workspace: 2, initialTitle: ^(LINE)$"
    "float, initialTitle: ^(LINE)$"

    # VLC
    "workspace: 3, initialClass: ^(vlc), floating: 0"

    # vesktop
    "workspace: 2 silent, initialClass: ^(vesktop), floating: 0"
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
}
