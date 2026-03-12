{
  pkgs,
  config,
  ...
}:
let
  inherit (config.networking) hostName;
  inherit (config.systemConf) username;
in
{
  home-manager.users."${username}" = {
    home.packages = with pkgs; [
      mattermost-desktop
    ];

    services.kanshi.settings = [
      {
        profile.name = hostName;
        profile.outputs = [
          {
            criteria = "LG Display 0x0665";
            position = "0,0";
            scale = 1.25;
          }
        ];
      }
    ];

    imports = [
      ../../../../home/presets/basic.nix
      ../../../../home/user/zellij.nix
      ./noctalia.nix
    ];
  };
}
