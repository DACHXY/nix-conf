{
  flake.modules.darwin.danny =
    { config, ... }:
    {
      system = {
        primaryUser = config.my.user.name;
        checks.verifyNixPath = false;
        defaults = {
          NSGlobalDomain = {
            AppleInterfaceStyle = "Dark";
            AppleInterfaceStyleSwitchesAutomatically = false;
            AppleShowScrollBars = "Automatic";

            KeyRepeat = 2;
            InitialKeyRepeat = 15;
            "com.apple.sound.beep.volume" = 0.0;
            "com.apple.sound.beep.feedback" = 0;
          };

          # --- Finder ---
          finder = {
            AppleShowAllExtensions = true;
          };

          # --- Login Window ---
          loginwindow = {
            GuestEnabled = false;
            SHOWFULLNAME = false;
          };

          # --- Screensaver & Lock ---
          screensaver = {
            askForPassword = true;
            askForPasswordDelay = 0; # 0 = immediately
          };

          # --- Screenshots ---
          screencapture = {
            type = "png"; # png, jpg, gif, pdf, tiff
            disable-shadow = true;
            include-date = true;
            location = "~/Pictures/screenshots";
          };

          # --- Control Center (Menu Bar) ---
          controlcenter = {
            BatteryShowPercentage = true;
            Bluetooth = true;
            Sound = true;
            Display = false;
            FocusModes = false;
            NowPlaying = false;
          };

          dock = {
            autohide = true;
            show-recents = false;
            launchanim = true;
            orientation = "bottom";
            tilesize = 40;
          };

          finder = {
            _FXShowPosixPathInTitle = false;
          };
        };
        keyboard = {
          enableKeyMapping = true;
          remapCapsLockToEscape = true;
        };
      };
    };

}
