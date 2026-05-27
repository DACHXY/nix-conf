{
  flake.modules.generic.base =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        file
        jq
        tldr
        wget
        killall
        fzf
      ];
    };

  flake.modules.nixos.base =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        unzip
        p7zip
        zip
        ffmpeg
        mpv
        imagemagick
      ];
    };

  flake.modules.nixos.gui =
    { config, ... }:
    {
      # For localsend
      networking.firewall.allowedTCPPorts = [ 53317 ];
      networking.firewall.allowedUDPPorts = [ 53317 ];

      home-manager.users.${config.my.user.name} =
        { pkgs, ... }:
        {
          home.packages = with pkgs; [
            cava
            trash-cli
            nemo
            thunderbird
            ffmpegthumbnailer
            libreoffice-qt
            papirus-folders
            localsend

            wl-clipboard
          ];
        };
    };
}
