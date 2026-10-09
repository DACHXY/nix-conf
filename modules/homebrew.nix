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
        "wallspace"
        "thunderbird"
        "vorssaint"
        "crossover"
        "caskhub"
        "sozercan/repo/kaset"
        "navbytes/tap/vee"
        "linearmouse"
      ];
    };
  };
}
