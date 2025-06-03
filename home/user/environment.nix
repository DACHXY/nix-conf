{
  home.sessionVariables = {
    BROWSER = "firefox";
    EDITOR = "nvim";
    TERMINAL = "ghostty";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
    GDK_BACKEND = "wayland";
    COLORTERM = "truecolor";
    NIXOS_OZONE_WL = "1";
    NIXOS_XDG_OPEN_USE_PORTAL = "1";

    QT_SCALE_FACTOR = "1";
    QT_QPA_PLATFORM = "wayland-egl";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    QT_IM_MODULES = "wayland;fcitx;ibus";

    MOZ_ENABLE_WAYLAND = "1";
    SDL_VIDEODRIVER = "wayland,x11";
    WLR_NO_HARDWARE_CURSORS = "1";
    CLUTTER_BACKEND = "wayland";
    EGL_PLATFORM = "wayland";
    WLR_RENDERER = "vulkan";

    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    XDG_CACHE_HOME = "\${HOME}/.cache";
    XDG_CONFIG_HOME = "\${HOME}/.config";
    XDG_DATA_HOME = "\${HOME}/.local/share";
    XDG_DATA_DIRS = "\${XDG_DATA_DIRS}:/usr/share:/var/lib/flatpak/exports/share:\${HOME}/.local/share/flatpak/exports/share";

    GTK_CSD = "0";
    GTK_USE_PORTAL = "1";
    GTK_IM_MODULE = "";

    MAIL = "~/Mailbox";
  };
}
