{
  config,
  inputs,
  self,
  ...
}:
let
  inherit (config.flake.public.config.ca) csrootca;
in
{
  flake.modules.homeManager.gui =
    {
      config,
      osConfig,
      pkgs,
      lib,
      ...
    }:
    let
      inherit (self.lib) capitalize;
      inherit (pkgs.stdenv.hostPlatform) system isDarwin;
      inherit (lib) optionalAttrs;

      username = osConfig.my.user.name;
      profileName = "${capitalize username}_Profile";

      zenMcp = pkgs.writeShellApplication {
        name = "zen-mcp";
        runtimeInputs = lib.optionals (!isDarwin) [ pkgs.procps ];
        text = ''
          if pgrep -x zen >/dev/null 2>&1 || pgrep -x zen-twilight >/dev/null 2>&1; then
            echo "zen-mcp: Zen is already running; the debug flags only apply at startup." >&2
            echo "zen-mcp: quit Zen, then run zen-mcp again." >&2
            exit 1
          fi
          exec ${lib.getExe' config.programs.zen-browser.package "zen-twilight"} \
            --marionette --remote-debugging-port=9222 "$@"
        '';
      };
    in
    {
      imports = [
        inputs.zen-browser.homeModules.twilight
      ];

      home.packages = [ zenMcp ];

      programs.zen-browser = {
        enable = true;
        setAsDefaultBrowser = true;
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
          Certificates = {
            Install = [
              csrootca
            ];
          };
          EnableTrackingProtection = {
            Value = true;
            Locked = true;
            Cryptomining = true;
            Fingerprinting = true;
          };
          SanitizeOnShutdown = {
            FormData = true;
            Cache = true;
          };

          Preferences = {
            "browser.aboutConfig.showWarning" = false;
            "media.videocontrols.picture-in-picture.video-toggle.enabled" = true;
            "browser.shell.checkDefaultBrowser" = false;
            "browser.shell.didSkipDefaultBrowserCheckOnFirstRun" = true;
            "browser.tabs.allow_transparent_browser" = true;
            "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
            "font.language.group" = "zh-TW";
            "network.http.http3.enabled" = true;
            "network.socket.ip_addr_any.disabled" = true; # disallow bind to 0.0.0.0
            "sidebar.expandOnHover" = false;
            "browser.ctrlTab.sortByRecentlyUsed" = true;
            "browser.tabs.insertAfterCurrent" = true;
            "signon.rememberSignons" = false;
            "extensions.formautofill.creditCards.enabled" = false;
          }
          // (optionalAttrs (!isDarwin) {
            "font.name.sans-serif.ja" = "Noto Sans CJK JP";
            "font.name.sans-serif.zh-TW" = "PingFang TC";
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
              "tether" = "tether@tether.com";
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

            mods = [
              "642854b5-88b4-4c40-b256-e035532109df" # Transparent Zen
              "e122b5d9-d385-4bf8-9971-e137809097d0" # No Top Sites
              "f50841b2-5e4a-4534-985d-b7f7b96088c2" # No Highlight Split
            ];

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
                url = "https://discord.com/app";
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
              "Element" = {
                id = "ad60fc37-6ee7-4591-9760-f5f50a7c948f";
                url = "https://element.dnywe.com";
                position = 190;
              };
            };
            pinsForce = false;

            keyboardShortcuts = [
              # Unbind
              {
                id = "key_netmonitor";
                disabled = true;
              }
              # Binds
              {
                id = "zen-compact-mode-toggle";
                key = "e";
                modifiers = {
                  control = !isDarwin;
                  meta = isDarwin;
                  shift = true;
                };
              }
              # Workspaces
              {
                id = "zen-workspace-forward";
                key = "e";
                modifiers = {
                  control = !isDarwin;
                  meta = isDarwin;
                  alt = true;
                };
              }
              {
                id = "zen-workspace-backward";
                key = "q";
                modifiers = {
                  control = !isDarwin;
                  meta = isDarwin;
                  alt = true;
                };
              }
              # Pins
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
            search.default = "google";
            search.force = true;
            search.privateDefault = "ddg";
            settings = {
              "zen.workspaces.continue-where-left-off" = true;
              "zen.view.compact.should-enable-at-startup" = true;
              "zen.widget.linux.transparency" = true;
              "zen.view.compact.show-sidebar-and-toolbar-on-hover" = false;
              "zen.tabs.vertical.right-side" = true;
              "zen.urlbar.behavior" = "float";
              "zen.welcome-screen.seen" = true;
              "zen.tabs.show-newtab-vertical" = false;

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
    };

  flake.modules.darwin.gui =
    { config, ... }:
    {
      home-manager.users.${config.my.user.name} =
        {
          config,
          osConfig,
          pkgs,
          lib,
          ...
        }:
        let
          inherit (self.lib) capitalize;
          username = osConfig.my.user.name;
          profileName = "${capitalize username}_Profile";

          # Official Zen icons from github:zen-browser/branding-archive.
          # Swap `zenIconName` for another key to change the icon.
          zenIcons = {
            "Zen-Dark-LightAcc" = "sha256-MG4iVfXU3EPr9UNFQy3mEB0LiOeOzv5Hk7sPo4kBrks=";
            "Zen-Dark-Coral" = "sha256-HkLqprQk2SSQRy2O4wtPvsMATjzJX3zh4w699WsYD/o=";
            "Zen-Color-Twilight" = "sha256-8dH0w8uxj9ACxVjkKRMDIkzFe4JsqqLchSKC9Yz/94s=";
            "Zen-Light-DarkAcc" = "sha256-XHwxwzZcb6EYi2qZ7hlLL9TTPmgrC4DOAzmdk86J7g8=";
            "Zen-3D-Dark" = "sha256-ndFdIc9A5fUzV5RyNus5RzazhprM/NkaaxPi7USGAis=";
          };
          zenIconName = "Zen-3D-Dark";
          zenIcon = pkgs.fetchurl {
            name = "${zenIconName}.icns";
            url = "https://raw.githubusercontent.com/zen-browser/branding-archive/main/Official/ICNS/${zenIconName}.icns";
            hash = zenIcons.${zenIconName};
          };

          # Home Manager copies the .app into ~/Applications on every switch, so
          # the replacement has to run after that copy. Swapping a resource
          # invalidates the signature, and a shallow re-sign leaves the nested
          # helpers on Firefox's Developer ID, so macOS refuses to open the app:
          # the whole bundle has to be sealed again as ad-hoc (`--deep`).
          zenApp = "${config.home.homeDirectory}/Applications/Home Manager Apps/Zen Browser (Twilight).app";
        in
        {
          programs.zen-browser.profiles.${profileName} = {
            keyboardShortcuts = [
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
          };

          home.activation.zenIcon = lib.hm.dag.entryAfter [ "linkGeneration" "copyApps" ] /* bash */ ''
            app="${zenApp}"
            if [ -d "$app" ]; then
              install -m 0644 ${zenIcon} "$app/Contents/Resources/firefox.icns"
              # home-manager activation replaces PATH with nix tools only, so
              # `codesign` has to be addressed absolutely or it silently no-ops.
              $DRY_RUN_CMD /usr/bin/codesign --force --deep --sign - --timestamp=none "$app" \
                >/dev/null 2>&1 || true
              touch "$app"
            fi
          '';
        };
    };

  flake.modules.nixos.gui =
    { config, ... }:
    {
      home-manager.users.${config.my.user.name} =
        {
          osConfig,
          config,
          pkgs,
          lib,
          ...
        }:
        let
          inherit (self.lib) capitalize;
          username = osConfig.my.user.name;
          profileName = "${capitalize username}_Profile";

          # Same official icon as the darwin module, but as a PNG: the desktop
          # entry is `zen-twilight.desktop` with Icon=zen-twilight, so a file
          # in the user hicolor tree shadows the packaged icon by name.
          zenIcon = pkgs.fetchurl {
            name = "Zen-3D-Dark.png";
            url = "https://raw.githubusercontent.com/zen-browser/branding-archive/main/Official/PNG/Zen-3D-Dark.png";
            hash = "sha256-gUn0jJ6BcnDZwHmEgSeVw5an7m8WARwxgyXTf+uWPY8=";
          };
        in
        {
          xdg.dataFile."icons/hicolor/512x512/apps/zen-twilight.png".source = zenIcon;
          programs.zen-browser.profiles.${profileName} = {
            keyboardShortcuts = [
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
          };

          systemd.user.tmpfiles.rules = [
            ''
              L+ ${config.home.homeDirectory}/.zen - - - - ${config.home.homeDirectory}/.config/zen
            ''
          ];

          xdg.mimeApps =
            let
              value = "zen-twilight.desktop";
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
              enable = true;
              associations.added = associations;
              defaultApplications = associations;
            };
        };
    };
}
