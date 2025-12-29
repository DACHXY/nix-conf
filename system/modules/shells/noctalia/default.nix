{ lib, config, ... }:
let

  inherit (config.systemConf) username;
  inherit (lib) mkForce mapAttrs;
in
{

  # ==== Extra Services Settings ==== #
  services.power-profiles-daemon.enable = true;
  networking.networkmanager.enable = true;
  services.upower.enable = true;
  hardware.bluetooth.enable = true;
  # ================================= #

  home-manager.users.${username} =
    { config, ... }:
    {
      # ==== Disabled Services ==== #
      services.swww.enable = mkForce false; # Wallpaper
      programs.waybar.enable = mkForce false; # Bar
      services.swayidle.enable = mkForce false; # Idle
      services.sunsetr.enable = mkForce false; # Bluelight filter
      programs.hyprlock.enable = mkForce false; # Lock
      services.swaync.enable = mkForce false; # Notification daemon

      systemd.user.services.noctalia-shell.Service.Environment = [
        "QT_QPA_PLATFORMTHEME=gtk3"
      ];

      programs.noctalia-shell = {
        enable = true;
        systemd.enable = true;
        settings = {
          settingsVersion = 25;
          appLauncher = {
            customLaunchPrefix = "";
            customLaunchPrefixEnabled = false;
            enableClipPreview = true;
            enableClipboardHistory = true;
            pinnedExecs = [
            ];
            position = "top_center";
            sortByMostUsed = true;
            terminalCommand = "ghostty -e";
            useApp2Unit = false;
            viewMode = "list";
          };
          audio = {
            cavaFrameRate = 30;
            externalMixer = "pwvucontrol";
            mprisBlacklist = [
            ];
            preferredPlayer = "mpv";
            visualizerQuality = "high";
            visualizerType = "linear";
            volumeOverdrive = false;
            volumeStep = 5;
          };
          bar = import ./bar.nix;
          brightness = {
            brightnessStep = 5;
            enableDdcSupport = false;
            enforceMinium = true;
          };
          calendar = {
            cards = [
              {
                enabled = true;
                id = "banner-card";
              }
              {
                enabled = true;
                id = "calendar-card";
              }
              {
                enabled = true;
                id = "timer-card";
              }
              {
                enabled = true;
                id = "weather-card";
              }
            ];
          };
          changelog = {
            lastSeenVersion = "";
          };
          colorSchemes = {
            darkMode = true;
            generateTemplatesForPredefined = true;
            manualSunrise = "06:30";
            manualSunset = "18:30";
            matugenSchemeType = "scheme-neutral";
            predefinedScheme = "Noctalia (default)";
            schedulingMode = "off";
            useWallpaperColors = true;
          };
          controlCenter = import ./controlCenter.nix;
          dock = {
            backgroundOpacity = 1;
            colorizeIcons = false;
            displayMode = "auto_hide";
            enabled = true;
            floatingRatio = 1;
            monitors = [
            ];
            onlySameOutput = true;
            pinnedApps = [
            ];
            radiusRatio = 0.68;
            size = 1;
          };
          general = {
            allowPanelsOnScreenWithoutBar = true;
            animationDisabled = false;
            animationSpeed = 1.5;
            avatarImage = "${config.home.homeDirectory}/.face";
            compactLockScreen = false;
            dimmerOpacity = 0.4;
            enableShadows = true;
            forceBlackScreenCorners = true;
            language = "";
            lockOnSuspend = true;
            radiusRatio = 1;
            scaleRatio = 1;
            screenRadiusRatio = 1.09;
            shadowDirection = "bottom_right";
            shadowOffsetX = 2;
            shadowOffsetY = 3;
            showHibernateOnLockScreen = false;
            showScreenCorners = true;
          };
          hooks = {
            enabled = false;
            darkModeChange = "";
            wallpaperChange = "";
          };
          location = {
            analogClockInCalendar = false;
            firstDayOfWeek = -1;
            name = "Taipei, TW";
            showCalendarEvents = true;
            showCalendarWeather = true;
            showWeekNumberInCalendar = false;
            use12hourFormat = false;
            useFahrenheit = false;
            weatherEnabled = true;
            weatherShowEffects = true;
          };
          network = {
            wifiEnabled = true;
          };
          nightLight = {
            enabled = true;
            autoSchedule = true;
            dayTemp = "6000";
            nightTemp = "5500";
            forced = false;
            manualSunrise = "06:30";
            manualSunset = "18:30";
          };
          notifications = {
            backgroundOpacity = 1;
            criticalUrgencyDuration = 15;
            enableKeyboardLayoutToast = true;
            enabled = true;
            location = "bottom_right";
            lowUrgencyDuration = 3;
            monitors = [
            ];
            normalUrgencyDuration = 8;
            overlayLayer = true;
            respectExpireTimeout = false;
          };
          osd = {
            autoHideMs = 1500;
            backgroundOpacity = 1;
            enabled = true;
            enabledTypes = [
              0
              1
              2
            ];
            location = "right";
            monitors = [
            ];
            overlayLayer = true;
          };
          screenRecorder = {
            audioCodec = "opus";
            audioSource = "default_output";
            colorRange = "limited";
            directory = "${config.home.homeDirectory}/Videos";
            frameRate = 60;
            quality = "very_high";
            showCursor = true;
            videoCodec = "h264";
            videoSource = "portal";
          };
          sessionMenu = import ./sessionMenu.nix;
          systemMonitor = import ./systemMonitor.nix;
          templates = import ./templates.nix;
          ui = {
            fontDefault = config.stylix.fonts.sansSerif.name;
            fontDefaultScale = 1;
            fontFixed = config.stylix.fonts.monospace.name;
            fontFixedScale = 1;
            panelBackgroundOpacity = 1;
            panelsAttachedToBar = true;
            settingsPanelAttachToBar = true;
            tooltipsEnabled = true;
          };
          wallpaper = {
            directory = "${config.home.homeDirectory}/Pictures/Wallpapers";
            enableMultiMonitorDirectories = false;
            enabled = true;
            fillColor = "#000000";
            fillMode = "crop";
            hideWallpaperFilenames = true;
            monitorDirectories = [
            ];
            overviewEnabled = false;
            panelPosition = "follow_bar";
            randomEnabled = false;
            randomIntervalSec = 300;
            recursiveSearch = false;
            setWallpaperOnAllMonitors = true;
            transitionDuration = 1500;
            transitionEdgeSmoothness = 0.05;
            transitionType = "random";
            useWallhaven = false;
            wallhavenCategories = "111";
            wallhavenOrder = "desc";
            wallhavenPurity = "100";
            wallhavenQuery = "";
            wallhavenResolutionHeight = "";
            wallhavenResolutionMode = "atleast";
            wallhavenResolutionWidth = "";
            wallhavenSorting = "relevance";
          };
        };
      };

      programs.niri.settings =
        with config.lib.niri.actions;
        let
          noctalia = spawn "noctalia-shell" "ipc" "call";
        in
        {
          binds = mapAttrs (name: value: mkForce value) {
            # Core
            "Mod+Slash".action = noctalia "controlCenter" "toggle";
            "Alt+Space".action = noctalia "launcher" "toggle";
            "Mod+Ctrl+M".action = noctalia "lockScreen" "lock";

            # Utilities
            "Mod+Comma".action = noctalia "launcher" "clipboard";
            "Mod+Period".action = noctalia "launcher" "emoji";
            "Mod+F12".action = noctalia "screenRecorder" "toggle";
            "Mod+N".action = noctalia "notifications" "toggleHistory";
            "Mod+Ctrl+N".action = noctalia "notifications" "toggleDND";
            "Mod+Ctrl+W".action = noctalia "wallpaper" "toggle";
            "Mod+Ctrl+C".action = noctalia "launcher" "calculator";
            "Mod+Ctrl+Slash".action = noctalia "wallpaper" "random";

            # Media
            "XF86AudioPlay".action = noctalia "media" "playPause";
            "XF86AudioStop".action = noctalia "media" "pause";
            "XF86AudioPrev".action = noctalia "media" "previous";
            "XF86AudioNext".action = noctalia "media" "next";
            "Mod+Ctrl+Comma".action = noctalia "media" "previous";
            "Mod+Ctrl+Period".action = noctalia "media" "next";
            "XF86AudioMute".action = noctalia "volume" "muteOutput";
            "XF86AudioRaiseVolume".action = noctalia "volume" "increase";
            "XF86AudioLowerVolume".action = noctalia "volume" "decrease";
            "XF86MonBrightnessDown".action = noctalia "brightness" "decrease";
            "XF86MonBrightnessUp".action = noctalia "brightness" "increase";
          };
        };
    };
}
