{
  inputs,
  osConfig,
  helper,
  pkgs,
  lib,
  ...
}:
let
  inherit (osConfig.systemConf) username;
  inherit (helper) capitalize;
  inherit (pkgs.stdenv.hostPlatform) system;
  inherit (pkgs.stdenv) isDarwin;
  inherit (lib) optionalAttrs;

  profileName = "${capitalize username}_Profile";
in
{
  programs.zen-browser = {
    enable = true;
    setAsDefaultBrowser = true;
    darwinDefaultsId = "org.mozilla.firefox.plist";
    package = inputs.zen-browser.packages.${system}.twilight;
    languagePacks = [
      "en-US"
      "zh-Tw"
    ];

    policies = {
      AutofillAddressEnabled = true;
      AutofillCreditCardEnabled = false;
      DisableAppUpdate = true;
      DisableFeedbackCommands = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DisableTelemetry = true;
      DontCheckDefaultBrowser = true;
      NoDefaultBookmarks = true;
      OfferToSaveLogins = false;
      EnableTrackingProtection = {
        Value = true;
        Locked = true;
        Cryptomining = true;
        Fingerprinting = true;
      };

      Preferences = {
        "browser.aboutConfig.showWarning" = false;
        "browser.shell.checkDefaultBrowser" = false;
        "browser.shell.didSkipDefaultBrowserCheckOnFirstRun" = true;
        "browser.tabs.allow_transparent_browser" = true;
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "font.language.group" = "zh-TW";
        "sidebar.expandOnHover" = false;
      }
      // (optionalAttrs (!isDarwin) {
        "font.name.sans-serif.ja" = "Noto Sans CJK JP";
        "font.name.sans-serif.zh-TW" = "Noto Sans CJK TC";
        "font.name.serif.ja" = "Noto Serif CJK JP";
        "font.name.serif.zh-TW" = "Noto Serif CJK TC";
        "font.name.monospace.zh-TW" = "Noto Sans Mono CJK TC";
        "font.name.monospace.ja" = "Noto Sans Mono CJK JP";
        "font.name.monospace.x-western" = "CaskaydiaCove Nerd Font Mono";
      });

      ExtensionSettings =
        let
          mkExtensionSettings = builtins.mapAttrs (
            _: pluginId: {
              install_url = "https://addons.mozilla.org/firefox/downloads/latest/${pluginId}/latest.xpi";
              installation_mode = "force_installed";
            }
          );
        in
        (mkExtensionSettings {
          "{446900e4-71c2-419f-a6a7-df9c091e268b}" = "bitwarden-password-manager";
          "{4f391a9e-8717-4ba6-a5b1-488a34931fcb}" = "bonjourr-startpage";
          "addon@darkreader.org" = "darkreader";
          "firefox@ghostery.com" = "ghostery";
          "{7a7a4a92-a2a0-41d1-9fd7-1e92480d612d}" = "styl-us";
          "firefox@tampermonkey.net" = "tampermonkey";
          "user-agent-switcher@ninetailed.ninja" = "uaswitcher";
          "{d7742d87-e61d-4b78-b8a1-b469842139fa}" = "vimium-ff";
          "{91aa3897-2634-4a8a-9092-279db23a7689}" = "zen-internet";
        })
        // {
          "moz-addon-prod@7tv.app" = {
            install_url = "https://extension.7tv.gg/v3.1.13/ext.xpi";
            installation_mode = "force_installed";
          };
        };
    };

    profiles = {
      "${profileName}" = {
        isDefault = true;
        name = username;
        sine = {
          enable = true;
          mods = [ "Nebula" ];
        };
        pins = {
          "Instagram" = {
            id = "9813885d-e361-420a-9018-dfaa1f2cbdb9";
            url = "https://www.instagram.com/direct/t";
            isEssential = true;
            position = 100;
          };
          "Youtube" = {
            id = "c4474b1d-462c-4362-8d79-a7f61f560bd8";
            url = "https://www.youtube.com";
            isEssential = true;
            position = 110;
          };
          "AniGamer" = {
            id = "e73966f0-4a8a-46ca-8200-6be859b6058a";
            url = "https://ani.gamer.com.tw";
            isEssential = true;
            position = 120;
          };
          "Github" = {
            id = "77d6c637-0fcd-456e-b7e6-f161325a2a91";
            url = "https://github.com";
            isEssential = true;
            position = 130;
          };
          "ChatGPT" = {
            id = "3703b7f4-b2c0-4b0e-98c1-f02aa2f7ec09";
            url = "https://chatgpt.com";
            isEssential = true;
            position = 140;
          };
          "Discord" = {
            id = "ff47d812-b089-4fa3-b1b0-8f8d7def5b63";
            url = "https://discord.com";
            isEssential = true;
            position = 150;
          };
          "nextcloud" = {
            id = "09f7ca95-9c82-46df-822a-47ffc8fa3eb0";
            url = "https://nextcloud.dnywe.com";
            position = 160;
          };
          "Home" = {
            id = "74bc74e7-fd42-4a44-a9ab-f1b85eef4bae";
            url = "https://www.dnywe.com";
            position = 170;
          };
          "Notion" = {
            id = "42ed89c2-820c-4a48-824e-39c8bd94b67c";
            url = "https://notion.so";
            position = 180;
          };
          "Element" = {
            id = "ad60fc37-6ee7-4591-9760-f5f50a7c948f";
            url = "https://element.dnywe.com";
            position = 190;
          };
          "ntfy" = {
            id = "922a3de0-f2e8-4efb-b6c0-9499095c00e8";
            url = "https://ntfy.dnywe.com";
            position = 200;
          };
          "teams" = {
            id = "1b43051f-d873-4854-a99a-fdec88a5240f";
            url = "https://teams.cloud.microsoft";
            position = 210;
          };
        };
        pinsForce = true;

        keyboardShortcuts = [
          {
            id = "zen-compact-mode-toggle";
            key = "e";
            modifiers = {
              control = true;
              shift = true;
            };
          }
          # Unbind
          {
            id = "key_netmonitor";
            key = "";
          }

          {
            id = "key_selectTab1";
            key = "1";
            modifiers = {
              alt = true;
            };
          }
          {
            id = "key_selectTab2";
            key = "2";
            modifiers = {
              alt = true;
            };
          }
          {
            id = "key_selectTab3";
            key = "3";
            modifiers = {
              alt = true;
            };
          }
          {
            id = "key_selectTab4";
            key = "q";
            modifiers = {
              alt = true;
            };
          }
          {
            id = "key_selectTab5";
            key = "w";
            modifiers = {
              alt = true;
            };
          }
          {
            id = "key_selectTab6";
            key = "e";
            modifiers = {
              alt = true;
            };
          }
          {
            id = "key_selectTab7";
            key = "a";
            modifiers = {
              alt = true;
            };
          }
          {
            id = "key_selectTab8";
            key = "s";
            modifiers = {
              alt = true;
            };
          }
          {
            id = "key_selectLastTab";
            key = "d";
            modifiers = {
              alt = true;
            };
          }
        ];
        keyboardShortcutsVersion = 17;

        search.default = "google";
        search.force = true;
        search.privateDefault = "ddg";
        settings = {
          "zen.view.compact.should-enable-at-startup" = true;
          "zen.widget.linux.transparency" = true;
          "zen.view.compact.show-sidebar-and-toolbar-on-hover" = false;
          "zen.tabs.vertical.right-side" = true;
          "zen.urlbar.behavior" = "float";
          "zen.welcome-screen.seen" = true;

          # Nebula
          "nebula-tab-loading-animation" = 0;
          "nebula-essentials-gray-icons" = false;
          "nebula-compact-mode-no-sidebar-bg" = true;
          "nebula-disable-container-styling" = true;

          "app.update.auto" = false;
          "app.normandy.first_run" = false;
          "middlemouse.paste" = false;
        };
      };
    };
  };
}
