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
        "theboredteam/boring-notch/boring-notch"
        "wallspace"
        "thunderbird"
        "vorssaint"
        "moonlight"
        "crossover"
      ];
    };
  };
}
