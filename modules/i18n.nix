{
  flake.modules.nixos.base = {
    i18n = {
      defaultLocale = "en_US.UTF-8";

      extraLocaleSettings = {
        LC_ADDRESS = "en_US.UTF-8";
        LC_IDENTIFICATION = "en_US.UTF-8";
        LC_MEASUREMENT = "en_US.UTF-8";
        LC_MONETARY = "en_US.UTF-8";
        LC_NAME = "en_US.UTF-8";
        LC_NUMERIC = "en_US.UTF-8";
        LC_PAPER = "en_US.UTF-8";
        LC_TELEPHONE = "en_US.UTF-8";
        LC_TIME = "en_US.UTF-8";
      };
      supportedLocales = [
        "en_US.UTF-8/UTF-8"
      ];
    };
  };

  flake.modules.nixos.gui =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      username = config.my.user.name;
      addons = with pkgs; [
        fcitx5-gtk
        fcitx5-mozc # Japanese
        qt6Packages.fcitx5-chinese-addons
        fcitx5-rime # Bopomofo
        rime-data
      ];
    in
    {
      home-manager.users.${username} = {
        # fcitx5-with-addons ships an XDG autostart entry
        # (org.fcitx.Fcitx5.desktop) that systemd turns into
        # app-org.fcitx.Fcitx5@autostart.service. That instance races the
        # home-manager fcitx5-daemon.service for the org.fcitx.Fcitx5 D-Bus
        # name; the loser exits 0 with "Unable to request dbus name".
        # Shadow the entry with Hidden=true so only fcitx5-daemon.service runs.
        xdg.configFile."autostart/org.fcitx.Fcitx5.desktop".text = ''
          [Desktop Entry]
          Type=Application
          Name=Fcitx 5
          Hidden=true
        '';

        i18n = {
          inputMethod = {
            enable = true;
            type = "fcitx5";
            fcitx5 = {
              inherit addons;
              waylandFrontend = true;

              # fcitx5 >= 5.1.22 truncates the 0x0 stretch area of a 9-slice
              # background. The stylix (mellow) theme's panel.svg is 30x30 with
              # 15px InputPanel margins, leaving a 0x0 middle, so the input panel
              # background renders fully transparent. Shrink the margins by 1.
              # https://github.com/nix-community/stylix/issues/2502
              themes.stylix.theme."InputPanel/Background/Margin" = lib.mkForce {
                Left = 14;
                Right = 14;
                Top = 14;
                Bottom = 14;
              };
              # highlight.svg is also 30x30; its 15px left/right margins leave a
              # 0-width middle for the same reason.
              themes.stylix.theme."InputPanel/Highlight/Margin" = lib.mkForce {
                Left = 14;
                Right = 14;
                Top = 10;
                Bottom = 10;
              };

              settings = {
                addons.classicui.globalSection =
                  let
                    font = "Noto Sans CJK TC ${toString config.stylix.fonts.sizes.popups}";
                  in
                  {
                    Font = lib.mkForce font;
                    MenuFont = lib.mkForce font;
                    TrayFont = lib.mkForce font;
                  };

                # fcitx5's keyboard engine binds Ctrl+Alt+H / Ctrl+Alt+J to
                # word-completion ("hint") mode, which eats herdr's pane
                # chords. Both are KeyListOptions whose KeyConstrain rejects a
                # key with no modifier, so an empty value is not accepted —
                # Configuration::load rolls the option back to its compiled
                # default instead. Point them at a chord no keyboard can send.
                addons.keyboard = {
                  sections = {
                    "Hint Trigger" = {
                      "0" = "Control+Alt+F35";
                    };
                    "One Time Hint Trigger" = {
                      "0" = "Control+Alt+F35";
                    };
                  };
                };

                # mozc's "Hotkey to expand usage" is a plain Option<Key> with no
                # constrain, so an empty value really does unset it.
                addons.mozc.globalSection.ExpandKey = "";

                inputMethod = {
                  GroupOrder."0" = "Default";
                  "Groups/0" = {
                    Name = "Default";
                    "Default Layout" = "us";
                    DefaultIM = "rime";
                  };
                  "Groups/0/Items/0".Name = "keyboard-us";
                  "Groups/0/Items/1".Name = "rime";
                  "Groups/0/Items/2".Name = "mozc";
                };

                globalOptions = {
                  Hotkey = {
                    EnumerateWithRiggerKeys = true;
                    EnumerateSkipFirst = false;
                    ModifierOnlyKeyTimeout = 250;
                  };
                  "Hotkey/TriggerKeys" = {
                    "0" = "Super+space";
                  };
                  "Hotkey/AltTriggerKeys" = {
                    "0" = "Shift_L";
                  };
                  "Hotkey/EnumerateGroupForwardKeys" = {
                    "0" = "Super+space";
                  };
                  "Hotkey/PrevPage" = {
                    "0" = "Up";
                  };
                  "Hotkey/NextPage" = {
                    "0" = "Down";
                  };
                  Behavior = {
                    ActiveByDefault = false;
                    resetStateWhenFocusIn = "no";
                    ShareInputState = "no";
                    PreeditEnabledByDefault = true;
                    ShowInputMethodInformation = true;
                    ShowInputMethodInformationWhenFocusIn = false;
                    CompactInputMethodInformation = true;
                    DefaultPageSize = 5;
                    PreloadInputMethod = true;
                  };
                };
              };
            };
          };
        };
      };
    };
}
