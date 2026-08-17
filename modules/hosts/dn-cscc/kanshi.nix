{
  configurations.nixos.dn-cscc.module =
    { config, ... }:
    let
      inherit (config.networking) hostName;
    in
    {
      home-manager.users.${config.my.user.name} = {
        services.kanshi = {
          enable = true;
          settings = [
            {
              profile.name = "${hostName}";
              profile.outputs = [
                {
                  criteria = "Dell Inc. DELL U2724DE 4C1XL04";
                  mode = "2560x1440@120Hz";
                  position = "0,0";
                  scale = 1.0;
                }
                {
                  criteria = "Dell Inc. DELL U2422HE 3HFMNM3";
                  mode = "1920x1080@60Hz";
                  position = "2560,120";
                  scale = 1.0;
                }
              ];
            }
          ];
        };
      };
    };
}
