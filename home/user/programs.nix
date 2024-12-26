{ pkgs, ... }: {
  programs = {
    neovim = {
      enable = true;
      withNodeJs = true;
      withPython3 = true;
      extraLuaPackages = ps: [ ps.magick ];
      extraPackages = [ pkgs.imagemagick ];
    };

    vscode = {
      enable = true;
      package = pkgs.vscode.fhs;
    };

    firefox.profiles.danny.settings = {
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
    };


    # firefox = {
    #   enable = true;
    #   languagePacks = [
    #     "en-US"
    #     "zh-TW"
    #     "ja"
    #   ];
    #
    #   policies = {
    #     DontCheckDefaultBrowser = true;
    #     DisplayBookmarksToolbar = "never";
    #   };
    # };
  };
}
