{
  configurations.nixos.dn-workstation.module =
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
                  criteria = "eDP-2";
                  status = "disable";
                }
                {
                  criteria = "ASUSTek COMPUTER INC ASUS VG32VQ1B 0x00002271";
                  mode = "2560x1440@164.554001Hz";
                  position = "0,0";
                  scale = 1.0;
                }
                {
                  criteria = "Acer Technologies XV272U V3 1322131231233";
                  mode = "2560x1440@179.876999Hz";
                  position = "-1440,-600";
                  transform = "90";
                }
              ];
            }
            {
              profile.name = "AcerOnly";
              profile.outputs = [
                {
                  criteria = "eDP-2";
                  status = "disable";
                }
                {
                  criteria = "Acer Technologies XV272U V3 1322131231233";
                  mode = "2560x1440@179.876999Hz";
                  position = "0,0";
                  transform = "normal";
                  scale = 1.0;
                }
              ];
            }
          ];
        };
      };
    };
}
