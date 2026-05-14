{
  flake.modules.darwin.gui = {
    homebrew = {
      enable = true;
      onActivation = {
        autoUpdate = false;
        cleanup = "uninstall";
        upgrade = false;
      };

      casks = [
        "raycast"
        "mattermost"
        "boring-notch"
        "domzilla-caffeine"
        "wallspace"
        "utm"
      ];

      taps = [
        "theboredteam/boring-notch"
      ];

      masApps = {
        "RunCat" = 1429033973;
        "HiddenBar" = 1452453066;
      };
    };
  };
}
