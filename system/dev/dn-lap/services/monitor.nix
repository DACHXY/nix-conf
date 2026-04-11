# Keep awake when close lid if external pisplay plugged in
{ config, ... }:
let
  inherit (config.networking) hostName;
  inherit (config.systemConf) username;
in
{
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
  };

  home-manager.users."${username}" = {
    services.kanshi = {
      settings = [
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
        {
          profile.name = "hdmi-only";
          profile.outputs = [
            {
              criteria = "LG Display 0x0665";
              status = "disable";
              scale = 1.25;
            }
            {
              criteria = "Acer Technologies XV272U V3 1322131231233";
              position = "";
              scale = 1.0;
              status = "enable";
            }
          ];
        }
      ];
    };
  };
}
