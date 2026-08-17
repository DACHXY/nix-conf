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
        i18n = {
          inputMethod = {
            enable = true;
            type = "fcitx5";
            fcitx5 = {
              inherit addons;
              waylandFrontend = true;

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
