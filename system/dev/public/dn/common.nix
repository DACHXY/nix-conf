{ config, ... }:
let
  inherit (config.systemConf) username;
in
{
  systemConf = {
    face = ../../../../home/config/.face;
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
