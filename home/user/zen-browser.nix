{
  osConfig,
  config,
  helper,
  pkgs,
  ...
}:
let
  inherit (osConfig.systemConf) username;
  inherit (helper) capitalize;
  inherit (pkgs) runCommand;

  zenNebula = pkgs.fetchFromGitHub {
    owner = "JustAdumbPrsn";
    repo = "zen-nebula";
    rev = "main";
    sha256 = "sha256-wtntRAkOGm6fr396kqzqk+GyPk+ytifXTqqOp0YIvlw=";
  };

  patchedNebula =
    runCommand "patched-nebula"
      {
        src = zenNebula;
        buildInputs = with pkgs; [
          rsync
          coreutils
        ];
      }
      # Fix for nebula without `sine`
      ''
        mkdir -p $out/Nebula
        tail -n +28 $src/Nebula/Nebula-config.css > $out/Nebula/Nebula-config.css
        rsync -av --exclude "Nebula-config.css" $src/ $out/
      '';

  profileName = "${capitalize username} Profile";
in
{
  programs.zen-browser = {
    enable = true;
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
      Certificates.Install = [
        ../../system/extra/ca.crt
      ];

      Preferences = {
        "browser.aboutConfig.showWarning" = false;
        "browser.shell.checkDefaultBrowser" = false;
        "browser.shell.didSkipDefaultBrowserCheckOnFirstRun" = true;
        "browser.tabs.allow_transparent_browser" = true;
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "font.language.group" = "zh-TW";
        "font.name.sans-serif.ja" = "Noto Sans CJK JP";
        "font.name.sans-serif.zh-TW" = "Noto Sans CJK TC";
        "font.name.serif.ja" = "Noto Serif CJK JP";
        "font.name.serif.zh-TW" = "Noto Serif CJK TC";
        "font.name.monospace.ja" = "Noto Sans Mono CJK JP";
        "font.name.monospace.x-western" = "CaskaydiaCove Nerd Font Mono";
        "font.name.monospace.zh-TW" = "Noto Sans Mono CJK TC";
      };

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
        search.default = "google";
        search.privateDefault = "ddg";
        settings = {
          "zen.view.compact.should-enable-at-startup" = true;
          "zen.widget.linux.transparency" = true;
          "zen.view.compact.show-sidebar-and-toolbar-on-hover" = false;
          "zen.tabs.vertical.right-side" = true;
          "zen.urlbar.behavior" = "float";

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

  home.file.".zen/${profileName}/zen-keyboard-shortcuts.json".source =
    ../config/zen/zen-keyboard-shortcuts.json;

  home.file.".zen/${profileName}/chrome" = {
    source = patchedNebula;
    recursive = true;
  };

  xdg.mimeApps =
    let
      value =
        let
          zen-browser = config.programs.zen-browser.package;
        in
        zen-browser.meta.desktopFileName;

      associations = builtins.listToAttrs (
        map
          (name: {
            inherit name value;
          })
          [
            "application/x-extension-shtml"
            "application/x-extension-xhtml"
            "application/x-extension-html"
            "application/x-extension-xht"
            "application/x-extension-htm"
            "x-scheme-handler/unknown"
            "x-scheme-handler/mailto"
            "x-scheme-handler/chrome"
            "x-scheme-handler/about"
            "x-scheme-handler/https"
            "x-scheme-handler/http"
            "application/xhtml+xml"
            "application/json"
            "application/pdf"
            "text/html"
          ]
      );
    in
    {
      associations.added = associations;
      defaultApplications = associations;
    };
}
