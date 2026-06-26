{
  flake.modules.nixos.base = {
    environment.variables = {
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
      GDK_BACKEND = "wayland";
    };
  };

  flake.modules.nixos.gui = {
    environment.variables = {
      NIXOS_OZONE_WL = "1";

      QT_SCALE_FACTOR = "1";
      QT_QPA_PLATFORM = "wayland";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      QT_AUTO_SCREEN_SCALE_FACTOR = "1";
      QT_IM_MODULES = "wayland;fcitx;ibus";

      MOZ_ENABLE_WAYLAND = "1";
      SDL_VIDEODRIVER = "wayland";
      WLR_NO_HARDWARE_CURSORS = "1";
      CLUTTER_BACKEND = "wayland";
      EGL_PLATFORM = "wayland";
      XDG_SESSION_TYPE = "wayland";
    };
  };

  flake.modules.homeManager.gui = {
    home.sessionVariables = {
      TERMINAL = "ghostty";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
      WLR_RENDERER = "vulkan";

      GTK_CSD = "0";
      GTK_USE_PORTAL = "1";
      GTK_IM_MODULE = "";
    };
  };
}
