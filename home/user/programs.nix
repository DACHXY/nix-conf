{ pkgs, inputs, ... }:
let
  userChrome = builtins.readFile ../config/firefox/autohide_toolbox.css;
  profileSettings = {
    # about:config
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
  };

in
{
  programs = {
    vscode = {
      enable = true;
      package = pkgs.vscode;
    };

    obs-studio = {
      enable = true;
      plugins = with pkgs.obs-studio-plugins; [
        wlrobs
        obs-backgroundremoval
        obs-pipewire-audio-capture
      ];
    };

    firefox = {
      enable = true;
      # package = (pkgs.wrapFirefox (pkgs.firefox-unwrapped.override { pipewireSupport = true; }) { });
      package = inputs.firefox.packages.${pkgs.system}.firefox-nightly-bin;
      languagePacks = [
        "en-US"
        "zh-TW"
        "ja"
      ];

      policies = {
        DontCheckDefaultBrowser = true;
        DisplayBookmarksToolbar = "never";
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
}
