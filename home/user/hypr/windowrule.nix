{
  windowrule = [
    "pseudo, fcitx"
    "float, file_progress"
    "float, confirm"
    "float, dialog"
    "float, download"
    "float, notification"
    "float, error"
    "float, splash"
    "float, confirmreset"
    "float, title:Open File"
    "float, title:branchdialog"
    "float, viewnior"
    "float, pavucontrol-qt"
    "float, pavucontrol"
    "float, file-roller"
    "fullscreen, wlogout"
    "float, title:wlogout"
    "fullscreen, title:wlogout"
    "idleinhibit stayfocused, mpv"
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

    # Workspace assign
    "workspace: 5, class: ^(steam)$"

    # Line
    "workspace: 2, initialTitle: ^(LINE)$"
    "float, initialTitle: ^(LINE)$"

    # VLC 
    "workspace: 3, initialClass: ^(vlc)"
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

