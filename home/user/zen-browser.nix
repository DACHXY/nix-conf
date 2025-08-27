{
  pkgs,
  ...
}:
let
  zenNebula = pkgs.fetchFromGitHub {
    owner = "justadumbprsn";
    repo = "zen-nebula";
    rev = "main";
    sha256 = "sha256-f4J5ob/apKhxERUSvXE8QHMMsKJCQFRoMSo/Pw4LgTg=";
  };
in
{
  programs.zen-browser = {
    enable = true;
    profiles = {
      "Danny Profile" = {
        default = true;
        name = "Danny";
        settings = {
          "zen.view.compact.should-enable-at-startup" = true;
          "zen.widget.linux.transparency" = true;
          "zen.view.compact.show-sidebar-and-toolbar-on-hover" = false;
          "zen.tabs.vertical.right-side" = true;
          "zen.urlbar.behavior" = "float";
          "nebula-tab-loading-animation" = 0;

          "app.update.auto" = false;
          "app.normandy.first_run" = false;
          "browser.aboutConfig.showWarning" = false;
          "browser.shell.checkDefaultBrowser" = false;
          "browser.shell.didSkipDefaultBrowserCheckOnFirstRun" = true;
          "browser.tabs.allow_transparent_browser" = true;
          "browser.urlbar.placeholderName" = "Google";
          "browser.urlbar.placeholderName.private" = "DuckDuckGo";
          "middlemouse.paste" = false;
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
        ensureCACertifications = [
          ../../system/extra/ca.crt
        ];
        chrome = zenNebula;
      };
    };
  };
}
