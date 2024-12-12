{ inputs, ... }: {
  programs.firefox = {
    enable = true;

    profiles.danny = {
      extensions = with inputs.firefox-addons.packages."x86_64-linux"; [
        darkreader
        proton-pass
        to-google-translate
        view-image
        # ublock-origin
      ];
    };
  };

  programs.home-manager.enable = true;
}
