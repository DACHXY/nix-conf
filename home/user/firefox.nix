{
  ...
}:
let
  userChrome = builtins.readFile ../config/firefox/autohide_toolbox.css;
  profileSettings = {
    # about:config
    "middlemouse.paste" = false;
    "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
    "extensions.activeThemeID" = "firefox-compact-dark@mozilla.org";
    "font.language.group" = "zh-TW";
    "font.name.sans-serif.ja" = "Noto Sans CJK JP";
    "font.name.sans-serif.zh-TW" = "Noto Sans CJK TC";
    "font.name.serif.ja" = "Noto Serif CJK JP";
    "font.name.serif.zh-TW" = "Noto Serif CJK TC";
    "font.name.monospace.ja" = "Noto Sans Mono CJK JP";
    "font.name.monospace.x-western" = "CaskaydiaCove Nerd Font Mono";
    "font.name.monospace.zh-TW" = "Noto Sans Mono CJK TC";
    # Disable Ctrl+Q
    "browser.quitShortcut.disabled" = true;
    "security.enterprise_roots.enabled" = true;
  };
in
{
  programs = {
    firefox = {
      enable = true;
      # package = inputs.firefox.packages.${system}.firefox-nightly-bin;
      languagePacks = [
        "en-US"
        "zh-TW"
        "ja"
      ];

      policies = {
        DontCheckDefaultBrowser = true;
        DisplayBookmarksToolbar = "never";
        Certificates = {
          Install = [
            "~/.mozilla/certificates/step-ca.net.dn.crt"
          ];
        };
      };

      profiles.default = {
        id = 0;
        name = "default";
        isDefault = true;

        userChrome = userChrome;
        settings = profileSettings;
      };

      profiles.noOffload = {
        id = 1;
        name = "noOffload";
        isDefault = false;

        userChrome = userChrome;
        settings = profileSettings;
      };
    };
  };

  home.file = {
    ".mozilla/certificates/step-ca.net.dn.crt" = {
      source = ../../system/extra/ca.crt;
    };
  };
}
