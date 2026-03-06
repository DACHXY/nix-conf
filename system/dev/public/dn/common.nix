{
  self,
  config,
  pkgs,
  ...
}:
let
  inherit (config.systemConf) username;
  serverCfg = self.nixosConfigurations.dn-server.config;
  serverNextcloudCfg = serverCfg.services.nextcloud;
  nextcloudURL =
    (if serverNextcloudCfg.https then "https" else "http") + "://" + serverNextcloudCfg.hostName;
in
{
  systemConf = {
    face = pkgs.fetchurl {
      url = "${nextcloudURL}/s/NDHdYnwrLqt5Syk/preview";
      hash = "sha256-mrTL+Q9rfp/RSMN19ymv0tV4hcT+wkp3C1dLITvZuR8=";
    };
    domain = "dnywe.com";
  };

  home-manager.users."${username}" =
    { ... }:
    {
      imports = [
        # Git
        (import ../../../../home/user/git.nix {
          inherit username;
          email = "Danny01161013@gmail.com";
        })
      ];
    };
}
