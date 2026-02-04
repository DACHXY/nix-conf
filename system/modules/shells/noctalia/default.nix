{ lib, config, ... }:
let

  inherit (config.systemConf) username;
  inherit (builtins) mapAttrs;
  inherit (lib)
    mkForce
    removePrefix
    concatStringsSep
    mapAttrsToList
    mkIf
    ;
in
{

  # ==== Extra Services Settings ==== #
  services.power-profiles-daemon.enable = true;
  networking.networkmanager.enable = true;
  services.upower.enable = true;
  hardware.bluetooth.enable = true;
  # ================================= #

  home-manager.users.${username} =
    { osConfig, config, ... }:
    let
      wmCfg = config.wm;
      bindCfg = wmCfg.keybinds;
      mod = wmCfg.keybinds.mod;
      sep = wmCfg.keybinds.separator;
    in
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

      programs.noctalia-shell = {
        enable = true;
        systemd.enable = true;
        settings = {
          settingsVersion = 26;
          appLauncher = {
            customLaunchPrefix = "";
            customLaunchPrefixEnabled = false;
            enableClipPreview = true;
            enableClipboardHistory = true;
            pinnedExecs = [
            ];
            position = "top_center";
            sortByMostUsed = true;
            terminalCommand = "${wmCfg.app.terminal.run}";
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
          bar = import ./bar.nix { inherit lib; };
          brightness = {
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
            backgroundOpacity = 1.0;
            colorizeIcons = false;
            displayMode = "auto_hide";
            enabled = false;
            floatingRatio = 1;
            monitors = [
            ];
            onlySameOutput = true;
            pinnedApps = [
            ];
            size = 1;
          };
          general = {
            allowPanelsOnScreenWithoutBar = true;
            animationDisabled = false;
            animationSpeed = 1.5;
            avatarImage = "${config.home.homeDirectory}/.face";
            boxRadiusRatio = 0.68;
            iRadiusRatio = 0.68;
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
            backgroundOpacity = 1.0;
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
            backgroundOpacity = 1.0;
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
            panelBackgroundOpacity = mkForce 0.25;
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

      programs.niri.settings = mkIf osConfig.programs.niri.enable (
        with config.lib.niri.actions;
        let
          noctalia = spawn "noctalia-shell" "ipc" "call";
        in
        {
          binds = mapAttrs (name: value: mkForce value) {
            # Core
            "${bindCfg.toggle-control-center}".action = noctalia "controlCenter" "toggle";
            "${bindCfg.toggle-launcher}".action = noctalia "launcher" "toggle";
            "${bindCfg.lock-screen}".action = noctalia "lockScreen" "lock";

            # Utilities
            "${bindCfg.clipboard-history}".action = noctalia "launcher" "clipboard";
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
        }
      );

      wayland.windowManager.mango.settings = mkIf osConfig.programs.mango.enable (
        mkForce (
          let
            keybinds = concatStringsSep "\n" (
              mapAttrsToList (n: v: "bind=${n},spawn,${v}") (bindCfg.spawn-repeat // bindCfg.spawn)
            );
          in
          ''
            # Window effect
            blur=0
            blur_layer=0
            blur_optimized=1
            blur_params_num_passes = 2
            blur_params_radius = 5
            blur_params_noise = 0.02
            blur_params_brightness = 0.9
            blur_params_contrast = 0.9
            blur_params_saturation = 1.2

            shadows = 0
            layer_shadows = 0
            shadow_only_floating = 1
            shadows_size = 10
            shadows_blur = 15
            shadows_position_x = 0
            shadows_position_y = 0
            shadowscolor= 0x000000ff

            border_radius=${toString wmCfg.border.radius}
            no_radius_when_single=0
            focused_opacity=${toString wmCfg.window.opacity}
            unfocused_opacity=${toString wmCfg.window.opacity}

            # Animation Configuration(support type:zoom,slide)
            # tag_animation_direction: 1-horizontal,0-vertical
            animations=1
            layer_animations=1
            animation_type_open=slide
            animation_type_close=slide
            animation_fade_in=1
            animation_fade_out=1
            tag_animation_direction=1
            zoom_initial_ratio=0.3
            zoom_end_ratio=0.8
            fadein_begin_opacity=0.5
            fadeout_begin_opacity=0.8
            animation_duration_move=500
            animation_duration_open=400
            animation_duration_tag=350
            animation_duration_close=800
            animation_duration_focus=0
            animation_curve_open=0.46,1.0,0.29,1
            animation_curve_move=0.46,1.0,0.29,1
            animation_curve_tag=0.46,1.0,0.29,1
            animation_curve_close=0.08,0.92,0,1
            animation_curve_focus=0.46,1.0,0.29,1
            animation_curve_opafadeout=0.5,0.5,0.5,0.5
            animation_curve_opafadein=0.46,1.0,0.29,1

            # Scroller Layout Setting
            scroller_structs=20
            scroller_default_proportion=0.8
            scroller_focus_center=0
            scroller_prefer_center=0
            edge_scroller_pointer_focus=1
            scroller_default_proportion_single=1.0
            scroller_proportion_preset=0.5,0.8,1.0

            # Master-Stack Layout Setting
            new_is_master=1
            default_mfact=0.55
            default_nmaster=1
            smartgaps=0

            # Overview Setting
            hotarea_size=10
            enable_hotarea=1
            ov_tab_mode=0
            overviewgappi=5
            overviewgappo=30

            # Misc
            no_border_when_single=0
            axis_bind_apply_timeout=100
            focus_on_activate=1
            idleinhibit_ignore_visible=0
            sloppyfocus=1
            warpcursor=1
            focus_cross_monitor=0
            focus_cross_tag=0
            enable_floating_snap=0
            snap_distance=30
            cursor_size=24
            drag_tile_to_tile=1

            # keyboard
            repeat_rate=${toString wmCfg.input.keyboard.repeat-rate}
            repeat_delay=${toString wmCfg.input.keyboard.repeat-delay}
            numlockon=0
            xkb_rules_layout=us

            # Trackpad
            # need relogin to make it apply
            disable_trackpad=0
            tap_to_click=1
            tap_and_drag=1
            drag_lock=1
            trackpad_natural_scrolling=0
            disable_while_typing=1
            left_handed=0
            middle_button_emulation=0
            swipe_min_threshold=1

            # mouse
            # need relogin to make it apply
            mouse_natural_scrolling=0

            # Appearance
            gappih=5
            gappiv=5
            gappoh=10
            gappov=10
            scratchpad_width_ratio=0.8
            scratchpad_height_ratio=0.9
            borderpx=4
            rootcolor=0x${removePrefix "#" wmCfg.border.active.to}ff
            bordercolor=0x${removePrefix "#" wmCfg.border.active.from}ff
            focuscolor=0x${removePrefix "#" wmCfg.border.active.to}ff
            maximizescreencolor=0x89aa61ff
            urgentcolor=0xad401fff
            scratchpadcolor=0x516c93ff
            globalcolor=0xb153a7ff
            overlaycolor=0x14a57cff

            # layout support:
            # tile,scroller,grid,deck,monocle,center_tile,vertical_tile,vertical_scroller
            tagrule=id:1,layout_name:tile
            tagrule=id:2,layout_name:tile
            tagrule=id:3,layout_name:tile
            tagrule=id:4,layout_name:tile
            tagrule=id:5,layout_name:tile
            tagrule=id:6,layout_name:tile
            tagrule=id:7,layout_name:tile
            tagrule=id:8,layout_name:tile
            tagrule=id:9,layout_name:tile

            # Key Bindings
            # key name refer to `xev` or `wev` command output,
            # mod keys name: super,ctrl,alt,shift,none

            ${keybinds}

            # exit
            bind=${bindCfg.close-window},killclient

            # switch window focus
            bind=${bindCfg.switch-window-focus},focusstack,next
            bind=${bindCfg.move-window-focus.left},focusdir,left
            bind=${bindCfg.move-window-focus.right},focusdir,right
            bind=${bindCfg.move-window-focus.up},focusdir,up
            bind=${bindCfg.move-window-focus.down},focusdir,down

            # swap window
            bind=${bindCfg.move-window.up},exchange_client,up
            bind=${bindCfg.move-window.down},exchange_client,down
            bind=${bindCfg.move-window.left},exchange_client,left
            bind=${bindCfg.move-window.right},exchange_client,right

            # switch window status
            bind=SUPER,g,toggleglobal,
            bind=${bindCfg.toggle-overview},toggleoverview,
            bind=${bindCfg.toggle-float},togglefloating,
            bind=${bindCfg.maximize-column},togglemaximizescreen,
            # bind=${bindCfg.toggle-fullscreen},togglefullscreen,
            bind=${bindCfg.toggle-fullscreen},togglefakefullscreen,
            bind=${bindCfg.minimize},minimized,
            # bind=SUPER,o,toggleoverlay,
            bind=${bindCfg.restore-minimize},restore_minimized
            bind=${bindCfg.toggle-scratchpad},toggle_scratchpad

            # scroller layout
            bind=${bindCfg.expand-column-to-available-width},set_proportion,1.0
            bind=${bindCfg.switch-preset-column-width},switch_proportion_preset,

            # switch layout
            bind=${bindCfg.switch-layout},switch_layout

            # tag switch
            bind=SUPER,Left,viewtoleft,0
            bind=CTRL,Left,viewtoleft_have_client,0
            bind=SUPER,Right,viewtoright,0
            bind=CTRL,Right,viewtoright_have_client,0
            bind=CTRL+SUPER,Left,tagtoleft,0
            bind=CTRL+SUPER,Right,tagtoright,0

            bind=${bindCfg.focus-workspace-prefix},1,view,1,0
            bind=${bindCfg.focus-workspace-prefix},2,view,2,0
            bind=${bindCfg.focus-workspace-prefix},3,view,3,0
            bind=${bindCfg.focus-workspace-prefix},4,view,4,0
            bind=${bindCfg.focus-workspace-prefix},5,view,5,0
            bind=${bindCfg.focus-workspace-prefix},6,view,6,0
            bind=${bindCfg.focus-workspace-prefix},7,view,7,0
            bind=${bindCfg.focus-workspace-prefix},8,view,8,0
            bind=${bindCfg.focus-workspace-prefix},9,view,9,0

            # tag: move client to the tag and focus it
            # tagsilent: move client to the tag and not focus it
            # bind=Alt,1,tagsilent,1
            bind=Alt,1,tag,1,0
            bind=Alt,2,tag,2,0
            bind=Alt,3,tag,3,0
            bind=Alt,4,tag,4,0
            bind=Alt,5,tag,5,0
            bind=Alt,6,tag,6,0
            bind=Alt,7,tag,7,0
            bind=Alt,8,tag,8,0
            bind=Alt,9,tag,9,0

            # monitor switch
            bind=${bindCfg.move-monitor-focus.left},focusmon,left
            bind=${bindCfg.move-monitor-focus.right},Right,focusmon,right
            bind=SUPER+Alt,Left,tagmon,left
            bind=SUPER+Alt,Right,tagmon,right

            # gaps
            # bind=ALT+SHIFT,X,incgaps,1
            # bind=ALT+SHIFT,Z,incgaps,-1
            # bind=ALT+SHIFT,R,togglegaps

            # movewin
            bind=CTRL+SHIFT,Up,movewin,+0,-50
            bind=CTRL+SHIFT,Down,movewin,+0,+50
            bind=CTRL+SHIFT,Left,movewin,-50,+0
            bind=CTRL+SHIFT,Right,movewin,+50,+0

            # resizewin
            bind=CTRL+ALT,Up,resizewin,+0,-50
            bind=CTRL+ALT,Down,resizewin,+0,+50
            bind=CTRL+ALT,Left,resizewin,-50,+0
            bind=CTRL+ALT,Right,resizewin,+50,+0

            # Mouse Button Bindings
            # NONE mode key only work in ov mode
            mousebind=SUPER,btn_left,moveresize,curmove
            mousebind=NONE,btn_middle,togglemaximizescreen,0
            mousebind=SUPER,btn_right,moveresize,curresize
            mousebind=NONE,btn_left,toggleoverview,1
            mousebind=NONE,btn_right,killclient,0

            # Axis Bindings
            axisbind=SUPER,UP,viewtoleft_have_client
            axisbind=SUPER,DOWN,viewtoright_have_client


            # layer rule
            layerrule=animation_type_open:zoom,layer_name:rofi
            layerrule=animation_type_close:zoom,layer_name:rofi

            # Core
            ${bindCfg.toggle-control-center},spawn,noctalia "controlCenter" "toggle";
            ${bindCfg.toggle-launcher},spawn,noctalia "launcher" "toggle";
            ${bindCfg.lock-screen},spawn,noctalia "lockScreen" "lock";

            # Utilities
            ${bindCfg.clipboard-history},spawn,noctalia "launcher" "clipboard";
            ${bindCfg.emoji},spawn,noctalia "launcher" "emoji";
            ${bindCfg.screen-recorder},spawn,noctalia "screenRecorder" "toggle";
            ${bindCfg.notification-center},spawn,noctalia "notifications" "toggleHistory";
            ${bindCfg.toggle-dont-disturb},spawn,noctalia "notifications" "toggleDND";
            ${bindCfg.wallpaper-selector},spawn,noctalia "wallpaper" "toggle";
            ${bindCfg.calculator},spawn,noctalia "launcher" "calculator";
            ${bindCfg.wallpaper-random},spawn,noctalia "wallpaper" "random";
          ''
        )
      );
    };
}
