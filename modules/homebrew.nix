{
  flake.modules.darwin.gui = {
    homebrew = {
      enable = true;
      enableFishIntegration = true;
      onActivation = {
        autoUpdate = false;
        cleanup = "uninstall";
        upgrade = false;
      };

      casks = [
        "TheBoredTeam/boring-notch/boring-notch"
        "domzilla-caffeine"
        "wallspace"
      ];

      masApps = {
        "CleanMyKeyboard" = 6468120888;
      };
    };
  };
}
