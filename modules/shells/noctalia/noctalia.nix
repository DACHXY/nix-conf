{ inputs, config, ... }:
{

  flake.modules.nixos.noctalia =
    nixosArgs:
    let
      inherit (nixosArgs.config.my.user) name;
    in
    {
      imports = [
        config.flake.modules.nixos.niri
      ];

      home-manager.users.${name}.imports = [
        config.flake.modules.homeManager.noctalia
      ];

      services.power-profiles-daemon.enable = true;
      networking.networkmanager.enable = true;
      services.upower.enable = true;
      hardware.bluetooth.enable = true;

      # Calendar Service
      # Run `nix shell nixpkgs#gnome-control-center -c bash -c "XDG_CURRENT_DESKTOP=GNOME gnome-control-center"`,
      # Then login to service. Check: https://nixos.wiki/wiki/GNOME/Calendar
      programs.dconf.enable = true;
      services.gnome.evolution-data-server.enable = true;
      services.gnome.gnome-online-accounts.enable = true;
      services.gnome.gnome-keyring.enable = true;
    };

  flake.modules.homeManager.noctalia =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      inherit (lib)
        listToAttrs
        mapAttrs
        mkForce
        mkDefault
        getExe'
        getExe
        ;

      wmCfg = config.wm;
      bindCfg = wmCfg.keybinds;
      mod = wmCfg.keybinds.mod;
      sep = wmCfg.keybinds.separator;

      noctalia-settings = pkgs.writeShellScriptBin "noctalia-settings" ''
        PATH="$PATH:${pkgs.jq}/bin:${pkgs.nixfmt}/bin"
        tmp=$(mktemp)

        noctalia-shell ipc call state all | jq -S .settings > "$tmp"

        nix eval --impure --expr \
        "(builtins.fromJSON (builtins.readFile \"$tmp\"))$1" \
        | nixfmt

        rm "$tmp"
      '';

      netbirdAlias = pkgs.writeShellScriptBin "netbird" ''
        netbird-wt0 $@
      '';
    in
    {
      imports = [
        inputs.noctalia.homeModules.default
      ];

      wm.keybinds.spawn-repeat = {
        # ==== Media ==== #
        "XF86AudioPrev" = ''noctalia "media" "previous"'';
        "XF86AudioNext" = ''noctalia "media" "next"'';
        "${mod}${sep}CTRL${sep}COMMA" = ''noctalia "media" "previous"'';
        "${mod}${sep}CTRL${sep}PERIOD" = ''noctalia "media" "next"'';
        "XF86AudioPlay" = ''noctalia "media" "playPause"'';
        "XF86AudioStop" = ''noctalia "media" "pause"'';
        "XF86AudioMute" = ''noctalia "volume" "muteOutput"'';
        "XF86AudioRaiseVolume" = ''noctalia "volume" "increase"'';
        "XF86AudioLowerVolume" = ''noctalia "volume" "decrease"'';
        "XF86MonBrightnessDown" = ''noctalia "brightness" "decrease"'';
        "XF86MonBrightnessUp" = ''noctalia "brightness" "increase"'';
      };

      # Install Required Packages
      home.packages = with pkgs; [
        # Alias netbird-wt0 to netbird
        netbirdAlias

        noctalia-settings

        # Output noctalia settings in nix format
        pkgs.gpu-screen-recorder

        pwvucontrol
        playerctl
      ];

      programs.noctalia-shell =
        let
          officialPlugins = [
            "niri-overview-launcher"
            "timer"
            "screen-recorder"
            "clipper"
            "battery-threshold"
            "polkit-agent"
            "todo"
            "custom-commands"
            "keybind-cheatsheet"
            "battery-action"
            "weekly-calendar"
            "privacy-indicator"
            "netbird"
            "network-manager-vpn"
          ];
          states = listToAttrs (
            map (x: {
              name = x;
              value = {
                enabled = true;
                sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
              };
            }) officialPlugins
          );
        in
        {
          enable = true;
          package = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
            calendarSupport = true;
          };
          colors = mkForce { };
          plugins = {
            sources = [
              {
                enabled = true;
                name = "Official Noctalia Plugins";
                url = "https://github.com/noctalia-dev/noctalia-plugins";
              }
            ];
            inherit states;
          };
          pluginSettings = {
            netbird = {
              compactMode = true;
              defaultPeerAction = "copy-ip";
              hideDisconnected = false;
              pingCount = 5;
              refreshInterval = 5000;
              showIpAddress = false;
              showPing = false;
            };
            privacy-indicator = {
              activeColor = "primary";
              enableToast = false;
              hideInactive = true;
              iconSpacing = 4;
              inactiveColor = "none";
              micFilterRegex = "";
              removeMargins = true;
            };
            custom-commands = {
              commands =
                let
                  getQRCode = pkgs.writeShellScriptBin "getQRcode" ''
                    notify() {
                      noctalia-shell ipc call toast send "$1"
                    }

                    if wl-paste --list-type | grep -q "image/png"; then
                      link=$(${getExe' pkgs.zbar.out "zbarimg"} <(wl-paste --type image/png) | sed 's/QR-Code://')
                      if [ -n "$link" ]; then
                        echo "$link" | wl-copy
                        notify "{\"title\":\"QR Code\",\"body\":\"$link\",\"icon\":\"link\"}"
                      else
                        notify '{"title":"QR Code","body":"Failed to decode QR.","icon":"error"}'
                      fi
                    else
                      notify '{"title":"QR Code","body":"No image found in clipboard.","icon":"warning"}'
                    fi
                  '';
                in
                [
                  {
                    name = "Get QRcode from clipboard";
                    command = "${getExe getQRCode}";
                    icon = "screenshot";
                  }
                ];
            };
          };
          settings = {
            appLauncher = {
              autoPasteClipboard = false;
              clipboardWatchImageCommand = "wl-paste --type image --watch cliphist store";
              clipboardWatchTextCommand = "wl-paste --type text --watch cliphist store";
              clipboardWrapText = true;
              customLaunchPrefix = "";
              customLaunchPrefixEnabled = false;
              density = "default";
              enableClipPreview = true;
              enableClipboardHistory = true;
              enableSessionSearch = true;
              enableSettingsSearch = true;
              enableWindowsSearch = true;
              iconMode = "tabler";
              ignoreMouseInput = false;
              overviewLayer = false;
              pinnedApps = [ ];
              position = "top_center";
              screenshotAnnotationTool = "";
              showCategories = true;
              showIconBackground = false;
              sortByMostUsed = true;
              terminalCommand = "${wmCfg.app.terminal.run}";
              useApp2Unit = false;
              viewMode = "list";
            };
            audio = {
              mprisBlacklist = [ ];
              preferredPlayer = "mpv";
              spectrumFrameRate = 30;
              visualizerType = "linear";
              volumeFeedback = false;
              volumeFeedbackSoundFile = "";
              volumeOverdrive = false;
              volumeStep = 5;
            };
            bar = {
              capsuleOpacity = mkForce 0;
              backgroundOpacity = mkForce 0.25;
              autoHideDelay = 500;
              autoShowDelay = 150;
              barType = "floating";
              capsuleColorKey = "none";
              contentPadding = 2;
              density = "comfortable";
              displayMode = "always_visible";
              floating = true;
              fontScale = 1;
              frameRadius = 12;
              frameThickness = 8;
              hideOnOverview = false;
              marginHorizontal = 5;
              marginVertical = 5;
              middleClickAction = "none";
              middleClickCommand = "";
              middleClickFollowMouse = false;
              monitors = [ ];
              mouseWheelAction = "none";
              mouseWheelWrap = true;
              outerCorners = false;
              position = "top";
              reverseScroll = false;
              rightClickAction = "controlCenter";
              rightClickCommand = "";
              rightClickFollowMouse = true;
              screenOverrides = [ ];
              showCapsule = true;
              showOnWorkspaceSwitch = true;
              showOutline = false;
              useSeparateOpacity = false;
              widgetSpacing = 6;
              widgets = {
                center = [
                  {
                    defaultSettings = {
                      activeColor = "primary";
                      enableToast = true;
                      hideInactive = false;
                      iconSpacing = 4;
                      inactiveColor = "none";
                      micFilterRegex = "";
                      removeMargins = false;
                    };
                    id = "plugin:privacy-indicator";
                  }
                  {
                    colorizeIcons = false;
                    hideMode = "hidden";
                    id = "ActiveWindow";
                    maxWidth = 145;
                    scrollingMode = "hover";
                    showIcon = true;
                    textColor = "none";
                    useFixedWidth = false;
                  }
                ];
                left = [
                  {
                    colorizeSystemIcon = "none";
                    enableColorization = false;
                    generalTooltipText = "";
                    hideMode = "alwaysExpanded";
                    icon = "rocket";
                    id = "CustomButton";
                    ipcIdentifier = "";
                    leftClickExec = "noctalia-shell ipc call launcher toggle";
                    leftClickUpdateText = false;
                    maxTextLength = {
                      horizontal = 10;
                      vertical = 10;
                    };
                    middleClickExec = "";
                    middleClickUpdateText = false;
                    parseJson = false;
                    rightClickExec = "";
                    rightClickUpdateText = false;
                    showExecTooltip = true;
                    showIcon = true;
                    showTextTooltip = true;
                    textCollapse = "";
                    textCommand = "";
                    textIntervalMs = 3000;
                    textStream = false;
                    wheelDownExec = "";
                    wheelDownUpdateText = false;
                    wheelExec = "";
                    wheelMode = "unified";
                    wheelUpExec = "";
                    wheelUpUpdateText = false;
                    wheelUpdateText = false;
                  }
                  { id = "plugin:weekly-calendar"; }
                  {
                    clockColor = "none";
                    customFont = "";
                    formatHorizontal = "HH:mm ddd, MMM dd";
                    formatVertical = "HH mm - dd MM";
                    id = "Clock";
                    tooltipFormat = "HH:mm ddd, MMM dd";
                    useCustomFont = false;
                  }
                  {
                    characterCount = 4;
                    colorizeIcons = false;
                    emptyColor = "secondary";
                    enableScrollWheel = true;
                    focusedColor = "primary";
                    followFocusedScreen = false;
                    fontWeight = "bold";
                    groupedBorderOpacity = 1;
                    hideUnoccupied = false;
                    iconScale = 0.8;
                    id = "Workspace";
                    labelMode = "index";
                    occupiedColor = "secondary";
                    pillSize = 0.6;
                    showApplications = false;
                    showBadge = true;
                    showLabelsOnlyWhenOccupied = true;
                    unfocusedIconsOpacity = 1;
                  }
                  {
                    compactMode = false;
                    hideMode = "hidden";
                    hideWhenIdle = false;
                    id = "MediaMini";
                    maxWidth = 250;
                    panelShowAlbumArt = true;
                    scrollingMode = "hover";
                    showAlbumArt = true;
                    showArtistFirst = false;
                    showProgressRing = true;
                    showVisualizer = true;
                    textColor = "none";
                    useFixedWidth = false;
                    visualizerType = "linear";
                  }
                ];
                right = [
                  {
                    blacklist = [ "Bluetooth*" ];
                    chevronColor = "none";
                    colorizeIcons = false;
                    drawerEnabled = false;
                    hidePassive = false;
                    id = "Tray";
                    pinned = [ ];
                  }
                  {
                    compactMode = true;
                    diskPath = "/";
                    iconColor = "none";
                    id = "SystemMonitor";
                    showCpuCores = false;
                    showCpuFreq = false;
                    showCpuTemp = true;
                    showCpuUsage = true;
                    showDiskAvailable = false;
                    showDiskUsage = false;
                    showDiskUsageAsPercent = false;
                    showGpuTemp = false;
                    showLoadAverage = false;
                    showMemoryAsPercent = false;
                    showMemoryUsage = true;
                    showNetworkStats = false;
                    showSwapUsage = false;
                    textColor = "none";
                    useMonospaceFont = true;
                    usePadding = false;
                  }
                  {
                    defaultSettings = {
                      connectedColor = "primary";
                      disconnectedColor = "none";
                      displayMode = "onhover";
                    };
                    id = "plugin:network-manager-vpn";
                  }
                  {
                    defaultSettings = {
                      compactMode = false;
                      defaultPeerAction = "copy-ip";
                      hideDisconnected = false;
                      pingCount = 5;
                      refreshInterval = 5000;
                      showIpAddress = true;
                      showPing = false;
                    };
                    id = "plugin:netbird";
                  }
                  {
                    defaultSettings = {
                      audioCodec = "opus";
                      audioSource = "default_output";
                      colorRange = "limited";
                      copyToClipboard = false;
                      directory = "";
                      filenamePattern = "recording_yyyyMMdd_HHmmss";
                      frameRate = "60";
                      hideInactive = false;
                      iconColor = "none";
                      quality = "very_high";
                      resolution = "original";
                      showCursor = true;
                      videoCodec = "h264";
                      videoSource = "portal";
                    };
                    id = "plugin:screen-recorder";
                  }
                  {
                    iconColor = "none";
                    id = "KeepAwake";
                    textColor = "none";
                  }
                  {
                    defaultSettings = {
                      completedCount = 0;
                      count = 0;
                      current_page_id = 0;
                      exportEmptySections = false;
                      exportFormat = "markdown";
                      exportPath = "~/Documents";
                      isExpanded = false;
                      pages = [
                        {
                          id = 0;
                          name = "General";
                        }
                      ];
                      priorityColors = {
                        high = "#f44336";
                        low = "#9e9e9e";
                        medium = "#2196f3";
                      };
                      showBackground = true;
                      showCompleted = true;
                      todos = [ ];
                      useCustomColors = false;
                    };
                    id = "plugin:todo";
                  }
                  {
                    displayMode = "onhover";
                    iconColor = "none";
                    id = "Volume";
                    middleClickCommand = "pwvucontrol || pavucontrol";
                    textColor = "none";
                  }
                  {
                    displayMode = "onhover";
                    iconColor = "none";
                    id = "Bluetooth";
                    textColor = "none";
                  }
                  {
                    hideWhenZero = true;
                    hideWhenZeroUnread = false;
                    iconColor = "none";
                    id = "NotificationHistory";
                    showUnreadBadge = true;
                    unreadBadgeColor = "primary";
                  }
                  {
                    deviceNativePath = "__default__";
                    displayMode = "graphic-clean";
                    hideIfIdle = true;
                    hideIfNotDetected = true;
                    id = "Battery";
                    showNoctaliaPerformance = false;
                    showPowerProfiles = false;
                  }
                  {
                    colorizeDistroLogo = false;
                    colorizeSystemIcon = "primary";
                    customIconPath = "";
                    enableColorization = true;
                    icon = "noctalia";
                    id = "ControlCenter";
                    useDistroLogo = true;
                  }
                ];
              };
            };
            brightness = {
              backlightDeviceMappings = [ ];
              brightnessStep = 5;
              enableDdcSupport = false;
              enforceMinimum = true;
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
            colorSchemes = {
              darkMode = true;
              generationMethod = "tonal-spot";
              manualSunrise = "06:30";
              manualSunset = "18:30";
              monitorForColors = "";
              predefinedScheme = "Noctalia (default)";
              schedulingMode = "off";
              useWallpaperColors = true;
            };
            controlCenter = {
              cards = [
                {
                  enabled = true;
                  id = "profile-card";
                }
                {
                  enabled = true;
                  id = "shortcuts-card";
                }
                {
                  enabled = true;
                  id = "audio-card";
                }
                {
                  enabled = true;
                  id = "weather-card";
                }
                {
                  enabled = true;
                  id = "media-sysmon-card";
                }
              ];
              diskPath = "/";
              position = "bottom_center";
              shortcuts = {
                left = [
                  { id = "Network"; }
                  { id = "Bluetooth"; }
                  { id = "WallpaperSelector"; }
                  {
                    defaultSettings = {
                      audioCodec = "opus";
                      audioSource = "default_output";
                      colorRange = "limited";
                      copyToClipboard = false;
                      directory = "${config.home.homeDirectory}/Videos";
                      filenamePattern = "recording_yyyyMMdd_HHmmss";
                      frameRate = "60";
                      hideInactive = false;
                      iconColor = "none";
                      quality = "very_high";
                      resolution = "original";
                      showCursor = true;
                      videoCodec = "h264";
                      videoSource = "portal";
                    };
                    id = "plugin:screen-recorder";
                  }
                ];
                right = [
                  { id = "Notifications"; }
                  { id = "PowerProfile"; }
                  { id = "KeepAwake"; }
                  { id = "NightLight"; }
                ];
              };
            };
            dock = {
              animationSpeed = 1;
              backgroundOpacity = mkForce 1.0;
              colorizeIcons = false;
              deadOpacity = 0.6;
              displayMode = "auto_hide";
              dockType = "floating";
              enabled = false;
              floatingRatio = 1;
              groupApps = false;
              groupClickAction = "cycle";
              groupContextMenuMode = "extended";
              groupIndicatorStyle = "dots";
              inactiveIndicators = false;
              indicatorColor = "primary";
              indicatorOpacity = 0.6;
              indicatorThickness = 3;
              launcherIconColor = "none";
              launcherPosition = "end";
              monitors = [ ];
              onlySameOutput = true;
              pinnedApps = [ ];
              pinnedStatic = false;
              position = "bottom";
              showDockIndicator = false;
              showLauncherIcon = false;
              sitOnFrame = false;
              size = 1;
            };
            general = {
              allowPanelsOnScreenWithoutBar = true;
              allowPasswordWithFprintd = false;
              animationDisabled = false;
              animationSpeed = 1.5;
              autoStartAuth = false;
              avatarImage = "${config.home.homeDirectory}/.face";
              boxRadiusRatio = 0.68;
              clockFormat = "hh\\nmm";
              clockStyle = "custom";
              compactLockScreen = false;
              dimmerOpacity = 0.4;
              enableBlurBehind = true;
              enableLockScreenCountdown = true;
              enableLockScreenMediaControls = false;
              enableShadows = true;
              forceBlackScreenCorners = true;
              iRadiusRatio = 0.68;
              keybinds = {
                keyDown = [ "Down" ];
                keyEnter = [
                  "Return"
                  "Enter"
                ];
                keyEscape = [ "Esc" ];
                keyLeft = [ "Left" ];
                keyRemove = [ "Del" ];
                keyRight = [ "Right" ];
                keyUp = [ "Up" ];
              };
              language = "";
              lockOnSuspend = true;
              lockScreenAnimations = false;
              lockScreenBlur = 0;
              lockScreenCountdownDuration = 3000;
              lockScreenMonitors = [ ];
              lockScreenTint = 0;
              passwordChars = false;
              radiusRatio = 1;
              reverseScroll = false;
              scaleRatio = 1;
              screenRadiusRatio = 1.09;
              shadowDirection = "bottom_right";
              shadowOffsetX = 2;
              shadowOffsetY = 3;
              showChangelogOnStartup = true;
              showHibernateOnLockScreen = false;
              showScreenCorners = true;
              showSessionButtonsOnLockScreen = true;
              telemetryEnabled = false;
            };
            hooks = {
              darkModeChange = "";
              enabled = false;
              performanceModeDisabled = "";
              performanceModeEnabled = "";
              screenLock = "";
              screenUnlock = "";
              session = "";
              startup = "";
              wallpaperChange = "";
            };
            location = {
              analogClockInCalendar = false;
              firstDayOfWeek = -1;
              hideWeatherCityName = false;
              hideWeatherTimezone = false;
              name = mkDefault "Taipei, TW";
              showCalendarEvents = true;
              showCalendarWeather = true;
              showWeekNumberInCalendar = false;
              use12hourFormat = false;
              useFahrenheit = false;
              weatherEnabled = true;
              weatherShowEffects = true;
            };
            network = {
              airplaneModeEnabled = false;
              bluetoothAutoConnect = true;
              bluetoothDetailsViewMode = "grid";
              bluetoothHideUnnamedDevices = false;
              bluetoothRssiPollIntervalMs = 60000;
              bluetoothRssiPollingEnabled = false;
              disableDiscoverability = false;
              networkPanelView = "wifi";
              wifiDetailsViewMode = "grid";
              wifiEnabled = true;
            };
            nightLight = {
              autoSchedule = true;
              dayTemp = "6000";
              enabled = true;
              forced = false;
              manualSunrise = "06:30";
              manualSunset = "18:30";
              nightTemp = "5500";
            };
            notifications = {
              backgroundOpacity = mkForce 1.00;
              clearDismissed = true;
              criticalUrgencyDuration = 15;
              density = "default";
              enableBatteryToast = true;
              enableKeyboardLayoutToast = true;
              enableMarkdown = true;
              enableMediaToast = false;
              enabled = true;
              location = "bottom_right";
              lowUrgencyDuration = 3;
              monitors = [ ];
              normalUrgencyDuration = 8;
              overlayLayer = true;
              respectExpireTimeout = false;
              saveToHistory = {
                critical = true;
                low = true;
                normal = true;
              };
              sounds = {
                criticalSoundFile = "";
                enabled = false;
                excludedApps = "discord,firefox,chrome,chromium,edge";
                lowSoundFile = "";
                normalSoundFile = "";
                separateSounds = false;
                volume = 0.5;
              };
            };
            osd = {
              autoHideMs = 1500;
              backgroundOpacity = mkForce 0.55;
              enabled = true;
              enabledTypes = [
                0
                1
                2
              ];
              location = "right";
              monitors = [ ];
              overlayLayer = true;
            };
            settingsVersion = 57;
            sessionMenu = {
              countdownDuration = 3000;
              enableCountdown = true;
              powerOptiolargeButtonsLayout = "single-row";
              largeButtonsStyle = true;
              position = "bottom_center";
              powerOptions = [
                {
                  action = "lock";
                  countdownEnabled = true;
                  enabled = true;
                  keybind = "1";
                }
                {
                  action = "suspend";
                  countdownEnabled = true;
                  enabled = true;
                  keybind = "2";
                }
                {
                  action = "hibernate";
                  countdownEnabled = true;
                  enabled = true;
                  keybind = "3";
                }
                {
                  action = "reboot";
                  countdownEnabled = true;
                  enabled = true;
                  keybind = "4";
                }
                {
                  action = "logout";
                  countdownEnabled = true;
                  enabled = true;
                  keybind = "5";
                }
                {
                  action = "shutdown";
                  countdownEnabled = true;
                  enabled = true;
                  keybind = "6";
                }
              ];
              showHeader = false;
              showKeybinds = true;
            };
            systemMonitor = {
              batteryCriticalThreshold = 5;
              batteryWarningThreshold = 20;
              cpuCriticalThreshold = 90;
              cpuWarningThreshold = 80;
              criticalColor = "";
              diskAvailCriticalThreshold = 10;
              diskAvailWarningThreshold = 20;
              diskCriticalThreshold = 90;
              diskWarningThreshold = 80;
              enableDgpuMonitoring = false;
              externalMonitor = "resources || missioncenter || jdsystemmonitor || corestats || system-monitoring-center || gnome-system-monitor || plasma-systemmonitor || mate-system-monitor || ukui-system-monitor || deepin-system-monitor || pantheon-system-monitor";
              gpuCriticalThreshold = 90;
              gpuWarningThreshold = 80;
              memCriticalThreshold = 90;
              memWarningThreshold = 80;
              swapCriticalThreshold = 90;
              swapWarningThreshold = 80;
              tempCriticalThreshold = 90;
              tempWarningThreshold = 80;
              useCustomColors = false;
              warningColor = "";
            };
            templates = {
              activeTemplates = [ ];
              enableUserTheming = false;
            };
            ui = {
              boxBorderEnabled = false;
              fontDefault = config.stylix.fonts.sansSerif.name;
              fontDefaultScale = 1;
              fontFixed = config.stylix.fonts.monospace.name;
              fontFixedScale = 1;
              panelBackgroundOpacity = mkForce 0.25;
              panelsAttachedToBar = true;
              settingsPanelMode = "attached";
              settingsPanelSideBarCardStyle = false;
              tooltipsEnabled = true;
            };
            wallpaper = {
              automationEnabled = false;
              directory = "${config.home.homeDirectory}/Pictures/Wallpapers";
              enableMultiMonitorDirectories = false;
              enabled = true;
              favorites = [ ];
              fillColor = "#000000";
              fillMode = "crop";
              hideWallpaperFilenames = true;
              monitorDirectories = [ ];
              overviewBlur = 0.4;
              overviewEnabled = true;
              overviewTint = 0.6;
              panelPosition = "follow_bar";
              randomIntervalSec = 300;
              setWallpaperOnAllMonitors = true;
              showHiddenFiles = false;
              skipStartupTransition = false;
              sortOrder = "name";
              transitionDuration = 1500;
              transitionEdgeSmoothness = 0.05;
              transitionType = "random";
              useSolidColor = false;
              useWallhaven = false;
              viewMode = "single";
              wallhavenApiKey = "";
              wallhavenCategories = "111";
              wallhavenOrder = "desc";
              wallhavenPurity = "100";
              wallhavenQuery = "";
              wallhavenRatios = "";
              wallhavenResolutionHeight = "";
              wallhavenResolutionMode = "atleast";
              wallhavenResolutionWidth = "";
              wallhavenSorting = "relevance";
              wallpaperChangeMode = "random";
            };
            plugins = {
              autoUpdate = true;
            };
            noctaliaPerformance = {
              disableDesktopWidgets = true;
              disableWallpaper = true;
            };
            desktopWidgets = {
              enabled = true;
              gridSnap = false;
              monitorWidgets = [ ];
              overviewEnabled = true;
            };
            idle = {
              customCommands = "[]";
              enabled = false;
              fadeDuration = 5;
              lockCommand = "";
              lockTimeout = 660;
              resumeLockCommand = "";
              resumeScreenOffCommand = "";
              resumeSuspendCommand = "";
              screenOffCommand = "";
              screenOffTimeout = 600;
              suspendCommand = "";
              suspendTimeout = 1800;
            };
          };
        };

      programs.niri.settings =
        with config.lib.niri.actions;
        let
          noctalia = spawn "noctalia-shell" "ipc" "call";
        in
        {
          spawn-at-startup = [
            { command = [ "QT_QPA_PLATFORMTHEME=gtk3 noctalia-shell" ]; }
          ];

          binds = mapAttrs (name: value: mkForce value) {
            # Core
            "${bindCfg.toggle-control-center}".action = noctalia "controlCenter" "toggle";
            "${bindCfg.toggle-launcher}".action = noctalia "launcher" "toggle";
            "${bindCfg.toggle-launcher-shortcuts}".action = noctalia "plugin:custom-commands" "toggle";
            "${bindCfg.lock-screen}".action = noctalia "lockScreen" "lock";

            # Utilities
            "${bindCfg.clipboard-history}".action = noctalia "plugin:clipper" "toggle";
            "${bindCfg.emoji}".action = noctalia "launcher" "emoji";
            "${bindCfg.screen-recorder}".action = noctalia "screenRecorder" "toggle";
            "${bindCfg.notification-center}".action = noctalia "notifications" "toggleHistory";
            "${bindCfg.toggle-dont-disturb}".action = noctalia "notifications" "toggleDND";
            "${bindCfg.wallpaper-selector}".action = noctalia "wallpaper" "toggle";
            "${bindCfg.calculator}".action = noctalia "launcher" "calculator";
            "${bindCfg.wallpaper-random}".action = noctalia "wallpaper" "random";

            # Media
            "XF86AudioPlay".action = noctalia "media" "playPause";
            "XF86AudioStop".action = noctalia "media" "pause";
            "XF86AudioPrev".action = noctalia "media" "previous";
            "XF86AudioNext".action = noctalia "media" "next";
            "${bindCfg.media.prev}".action = noctalia "media" "previous";
            "${bindCfg.media.next}".action = noctalia "media" "next";
            "XF86AudioMute".action = noctalia "volume" "muteOutput";
            "XF86AudioRaiseVolume".action = noctalia "volume" "increase";
            "XF86AudioLowerVolume".action = noctalia "volume" "decrease";
            "XF86MonBrightnessDown".action = noctalia "brightness" "decrease";
            "XF86MonBrightnessUp".action = noctalia "brightness" "increase";
          };
        };
    };
}
