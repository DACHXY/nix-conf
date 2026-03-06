{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkForce;
  inherit (config.networking) hostName;
  inherit (config.systemConf) username;
in
{
  home-manager.users."${username}" = {
    home.packages = with pkgs; [
      mattermost-desktop
    ];

    home.sessionVariables = {
      BROWSER = mkForce "chromium";
    };

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

    programs.noctalia-shell = {
      settings = { };
    };

    programs.chromium = {
      enable = true;
      extensions = [
        # Bitwarden
        {
          id = "nngceckbapebfimnlniiiahkandclblb";
        }
        # Vimium
        {
          id = "dbepggeogbaibhgnhhndojpepiihcmeb";
        }
        # Dark Reader
        {
          id = "eimadpbcbfnmbkopoojfekhnkhdbieeh";
        }
        # Vertical Tabs
        {
          id = "efobhjmgoddhfdhaflheioeagkcknoji";
        }
      ];
    };

    imports = [
      ../../../../home/presets/basic.nix
      ../../../../home/user/zellij.nix
    ];
  };
}
