{
  inputs,
  config,
  self,
  ...
}:
let
  globalConfig = config;
in
{
  flake.modules.nixos.noctalia =
    { pkgs, ... }@nixosArgs:
    let
      inherit (nixosArgs.config.my.user) name;
      noctalia-restart = pkgs.writeShellScriptBin "noctalia-restart" ''
        systemctl --user restart noctalia
      '';
    in
    {
      imports = [
        config.flake.modules.nixos.niri
      ];

      home-manager.users.${name} = {
        imports = [
          config.flake.modules.homeManager.noctalia
        ];
        home.packages = [
          noctalia-restart
        ];
      };

      services.power-profiles-daemon.enable = true;
      networking.networkmanager.enable = true;
      services.upower.enable = true;
      hardware.bluetooth.enable = true;
      systemd.user.services.niri-flake-polkit.enable = false;

      security.polkit.extraConfig = /* js */ ''
        polkit.addRule(function(action, subject) {
          if (
            action.id == "org.freedesktop.policykit.exec" &&
            action.lookup("program") == "/run/current-system/sw/bin/noctalia-greeter" &&
            subject.isInGroup("wheel")
          ) {
            return polkit.result.YES;
          }
        })
      '';
    };

  flake.modules.homeManager.noctalia =
    {
      pkgs,
      lib,
      config,
      osConfig,
      ...
    }:
    let
      inherit (lib)
        mapAttrs
        mkForce
        ;
      inherit (self.lib) capitalize;
      inherit (osConfig.my.user) name;

      wmCfg = config.wm;
      bindCfg = wmCfg.keybinds;
      mod = wmCfg.keybinds.mod;
      sep = wmCfg.keybinds.separator;

      netbirdAlias = pkgs.writeShellApplication {
        name = "netbird";
        text = ''
          netbird-wt0 "$@"
        '';
      };

      noctaliaSettings = pkgs.writeShellApplication {
        name = "noctalia-settings";
        text = ''
          nix run github:erooke/toml2nix <(noctalia config export merged)
        '';
      };
    in
    {
      imports = [
        inputs.noctalia.homeModules.default
      ];

      # Install Required Packages
      home.packages = with pkgs; [
        # Alias netbird-wt0 to netbird
        netbirdAlias
        noctaliaSettings

        gpu-screen-recorder
        pwvucontrol
        playerctl
        satty

        bitwarden-cli
      ];

      # ==== GTK Theme ==== #
      gtk.theme = {
        name = "adw-gtk3";
        package = pkgs.adw-gtk3;
      };

      systemd.user.services.noctalia-set-gtk-theme = {
        Install.WantedBy = [ "noctalia.service" ];
        Service = {
          Type = "oneshot";
          Environment = [
            "XDG_DATA_DIRS=${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:$XDG_DATA_DIRS"
          ];
          ExecStart = ''
            ${lib.getExe' pkgs.glib.bin "gsettings"} set org.gnome.desktop.interface gtk-theme 'adw-gtk3'
          '';
        };
      };

      # ==== Stylix ==== #
      stylix.targets = {
        gtk.enable = false;
        qt.enable = false;
        btop.enable = false;
        zed.enable = false;
        yazi.enable = false;
        obsidian.enable = false;
      };

      # ==== Btop ==== #
      programs.btop.settings.color_theme = "noctalia";

      systemd.user.services.noctalia.Service.Environment = [
        "QT_QPA_PLATFORMTHEME=gtk3"
      ];

      programs.noctalia = {
        enable = true;
        package = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
        systemd.enable = true;
        settings = {
          backdrop.enabled = true;
          bar.default = {
            background_opacity = 0.5;
            capsule = true;
            capsule_padding = 8.0;
            capsule_opacity = 0.4;
            center = [
              "privacy"
              "active_window"
            ];
            end = [
              "tray"
              "recorder"
              "clipboard"
              "caffeine"
              "network"
              "bluetooth"
              "volume"
              "cpu"
              "brightness"
              "battery"
              "notifications"
              "session"
            ];
            font_weight = 600;
            margin_ends = 10;
            margin_edge = 10;
            start = [
              "control-center"
              "launcher"
              "workspaces"
              "date"
              "clock"
              "media"
              "audio_visualizer"
            ];
            widget_spacing = 10;
          };

          calendar = {
            enabled = true;
            refresh_minutes = 5;
          };

          desktop_widgets = {
            schema_version = 2;
            widget_order = [ "desktop-widget-0000000000000001" ];

            grid = {
              cell_size = 16;
              major_interval = 4;
              visible = true;
            };

            widget = {
              "desktop-widget-0000000000000001" = {
                box_height = 112.0;
                box_width = 208.0;
                cx = 168.0;
                cy = 1320.0;
                output = "DP-3";
                rotation = 0.0;
                type = "clock";

                settings = {
                  background = false;
                  center_text = true;
                  clock_style = "digital";
                };
              };
            };
          };

          dock = {
            auto_hide = true;
            enabled = false;
            reserve_space = false;
          };

          idle = {
            behavior_order = [
              "lock"
              "screen-off"
              "lock-and-suspend"
            ];
            pre_action_fade_seconds = 5;

            behavior = {
              lock = {
                action = "lock";
                enabled = true;
                timeout = 600;
              };

              "lock-and-suspend" = {
                action = "lock_and_suspend";
                enabled = false;
                timeout = 900;
              };

              "screen-off" = {
                action = "screen_off";
                enabled = true;
                timeout = 660;
              };
            };
          };

          location = {
            auto_locate = true;
          };

          lockscreen_widgets = {
            enabled = true;
            schema_version = 2;
            widget_order = [
              "lockscreen-login-box@DP-3"
              "lockscreen-login-box@eDP-2"
              "lockscreen-login-box@DP-5"
              "lockscreen-widget-0000000000000001"
              "lockscreen-widget-0000000000000002"
              "lockscreen-widget-0000000000000005"
            ];

            grid = {
              cell_size = 16;
              major_interval = 4;
              visible = true;
            };

            widget = {
              "lockscreen-login-box@DP-3" = {
                box_height = 196.0;
                box_width = 720.0;
                cx = 1280.0;
                cy = 1232.0;
                output = "DP-3";
                rotation = 0.0;
                type = "login_box";
                settings = {
                  background_color = "on_primary";
                  background_opacity = 0.0;
                  background_radius = 12.0;
                  center_password_text = false;
                  input_opacity = 0.8;
                  input_radius = 32.0;
                  layout = "regular";
                  show_caps_lock = true;
                  show_keyboard_layout = true;
                  show_login_button = true;
                  show_media = true;
                  show_session_buttons = true;
                  show_unlock_hint = true;
                  show_weather = true;
                };
              };
              "lockscreen-login-box@DP-5" = {
                box_height = 196.0;
                box_width = 720.0;
                cx = 704.0;
                cy = 2504.0;
                enabled = false;
                output = "DP-5";
                rotation = 0.0;
                type = "login_box";
                settings = {
                  background_color = "surface_variant";
                  background_opacity = 0.88;
                  background_radius = 12.0;
                  center_password_text = false;
                  input_opacity = 1.0;
                  input_radius = 6.0;
                  layout = "regular";
                  show_caps_lock = true;
                  show_keyboard_layout = true;
                  show_login_button = true;
                  show_media = true;
                  show_session_buttons = true;
                  show_unlock_hint = true;
                  show_weather = true;
                };
              };
              "lockscreen-login-box@eDP-2" = {
                box_height = 196.0;
                box_width = 720.0;
                cx = 1024.0;
                cy = 1157.0;
                output = "eDP-2";
                rotation = 0.0;
                type = "login_box";
                settings = {
                  background_color = "surface_variant";
                  background_opacity = 0.88;
                  background_radius = 12.0;
                  center_password_text = false;
                  input_opacity = 1.0;
                  input_radius = 6.0;
                  layout = "regular";
                  show_caps_lock = true;
                  show_keyboard_layout = true;
                  show_login_button = true;
                  show_media = true;
                  show_session_buttons = true;
                  show_unlock_hint = true;
                  show_weather = true;
                };
              };
              lockscreen-widget-0000000000000001 = {
                box_height = 176.0;
                box_width = 464.0;
                cx = 1280.0;
                cy = 336.0;
                output = "DP-3";
                rotation = 0.0;
                type = "clock";
                settings = {
                  background = false;
                  shadow = false;
                };
              };
              lockscreen-widget-0000000000000005 = {
                box_height = 64.0;
                box_width = 224.0;
                cx = 1280.0;
                cy = 432.0;
                output = "DP-3";
                rotation = 0.0;
                type = "label";
                settings = {
                  background = false;
                  color = "on_surface";
                  description = "";
                  opacity = 0.65;
                  shadow = false;
                  title = "  Welcome Back, Danny !  ";
                };
              };
            };
          };

          nightlight = {
            enabled = true;
            temperature_night = 6400;
          };

          notification = {
            background_opacity = 0.55;
            position = "top_right";
          };

          osd = {
            background_opacity = 0.55;
            orientation = "horizontal";
            position = "bottom_center";
            position_vertical = "center_right";
            kinds = {
              media = false;
            };
          };

          plugin_settings = {
            "avivbintangaringga/nix-monitor" = {
              update_command = "${pkgs.writeShellApplication {
                name = "update-nix-flake";
                runtimeInputs = with pkgs; [
                  nix
                ];
                text = ''
                  FLAKE_REPO="${globalConfig.flake.public.config.common.nix-repo}"

                  cd "$FLAKE_REPO"
                  nix flake update
                '';
              }}";
              clean_command = "nh clean all";
            };
            "noctalia/bitwarden" = {
              server_url = globalConfig.flake.public.config.services.vaultwarden.endpoint;
            };
            "noctalia/screen_recorder" = {
              copy_to_clipboard = true;
            };
          };

          plugins = {
            enabled = [
              "noctalia/screen_recorder"
              "noctalia/timer"
              "noctalia/translator"
              "avivbintangaringga/nix-monitor"
              "noctalia/bitwarden"
              "avivbintangaringga/nextboot-selector"
            ];
            source = [
              {
                kind = "git";
                location = "https://github.com/noctalia-dev/community-plugins";
                name = "community";
              }
              {
                kind = "git";
                location = "https://github.com/noctalia-dev/official-plugins";
                name = "official";
              }
            ];
          };

          shell = {
            app_icon_color = "on_surface";
            avatar_path = "~/.face";
            clipboard_image_action_command = "satty -f -";
            launch_apps_as_systemd_services = true;
            niri_overview_type_to_launch_enabled = true;
            polkit_agent = true;
            screen_time_enabled = true;
            settings_show_advanced = true;
            time_format = "{:%-I:%M %p}";
            greeter_sync = {
              auto_sync = true;
              privilege_command = "ghostty -e pkexec";
            };

            panel = {
              borders = false;
              open_near_click_session = true;
              open_near_click_wallpaper = true;
              open_near_click_control_center = true;
              transparency_mode = "glass";
            };

            screen_corners = {
              enabled = true;
            };

            screenshot = {
              directory = "~/Pictures/Screenshots";
              save_to_file = false;
            };
          };

          theme = {
            source = "wallpaper";
            wallpaper_scheme = "muted";

            templates = {
              builtin_ids = [
                "btop"
                "gtk3"
                "gtk4"
                "qt"
              ];
              community_ids = [
                "obsidian"
                "zed"
                "steam"
                "yazi"
              ];
              enable_builtin_templates = true;
            };
          };

          wallpaper = {
            directory = "~/Pictures/Wallpapers";
            transition_on_startup = true;
          };

          widget = {
            battery = {
              display_mode = "graphic";
              hide_when_full = true;
            };
            clock = {
              format = "{:%-I:%M %p}";
            };
            launcher = {
              glyph = "rocket";
            };
            media = {
              hide_when_no_media = true;
              title_scroll = "on_hover";
            };
            network = {
              show_label = false;
            };
            privacy = {
              hide_inactive = true;
            };
            recorder = {
              type = "noctalia/screen_recorder:recorder";
            };
            tray = {
              hidden = [ "Blueman" ];
            };
          };
        };
      };

      programs.niri.settings =
        with config.lib.niri.actions;
        let
          noctalia = spawn "noctalia" "msg";
          panelToggle = noctalia "panel-toggle";
        in
        {
          binds = mapAttrs (_: value: mkForce value) {
            # Core
            "${bindCfg.toggle-control-center}".action = panelToggle "control-center";
            "${bindCfg.toggle-launcher}".action = panelToggle "launcher";
            "${bindCfg.toggle-launcher-shortcuts}".action = noctalia "plugin:custom-commands" "toggle";
            "${bindCfg.lock-screen}".action = noctalia "session" "lock";

            # Utilities
            "${bindCfg.clipboard-history}".action = panelToggle "clipboard";
            "${bindCfg.emoji}".action = panelToggle "launcher" "/emo ";
            "${bindCfg.screen-recorder}".action = noctalia "screenRecorder" "toggle";
            "${bindCfg.notification-center}".action = panelToggle "control-center" "notifications";
            "${bindCfg.toggle-dont-disturb}".action = noctalia "notification-dnd-toggle";
            "${bindCfg.wallpaper-selector}".action = panelToggle "wallpaper";
            "${bindCfg.windows-switcher}".action = panelToggle "launcher" "/win ";
            "${bindCfg.wallpaper-random}".action = noctalia "wallpaper-random";

            # Media
            "XF86AudioPlay".action = noctalia "media" "toggle";
            "XF86AudioStop".action = noctalia "media" "stop";
            "XF86AudioPrev".action = noctalia "media" "previous";
            "XF86AudioNext".action = noctalia "media" "next";
            "${bindCfg.media.prev}".action = noctalia "media" "previous";
            "${bindCfg.media.next}".action = noctalia "media" "next";
            "XF86AudioMute".action = noctalia "volume-mute";
            "XF86AudioRaiseVolume".action = noctalia "volume-up";
            "XF86AudioLowerVolume".action = noctalia "volume-down";
            "XF86MonBrightnessDown".action = noctalia "brightness-down";
            "XF86MonBrightnessUp".action = noctalia "brightness-up";
          };
        };

      wm.keybinds.spawn-repeat = {
        # ==== Media ==== #
        "XF86AudioPrev" = ''noctalia "media" "previous"'';
        "XF86AudioNext" = ''noctalia "media" "next"'';
        "${mod}${sep}CTRL${sep}COMMA" = ''noctalia "media" "previous"'';
        "${mod}${sep}CTRL${sep}PERIOD" = ''noctalia "media" "next"'';
        "XF86AudioPlay" = ''noctalia "media" "toggle"'';
        "XF86AudioStop" = ''noctalia "media" "stop"'';
        "XF86AudioMute" = ''noctalia "volume-mute"'';
        "XF86AudioRaiseVolume" = ''noctalia "volume-up"'';
        "XF86AudioLowerVolume" = ''noctalia "volume-down"'';
        "XF86MonBrightnessDown" = ''noctalia "brightness-down"'';
        "XF86MonBrightnessUp" = ''noctalia "brightness-up"'';
      };
    };
}
