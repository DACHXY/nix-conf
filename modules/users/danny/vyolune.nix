{ inputs, config, ... }:
let

  inherit (config.flake.public.config.services) nextcloud;
in
{

  flake.modules.nixos.danny-gui =
    { config, ... }:
    {
      home-manager.users.${config.my.user.name} = { config, ... }: {
        imports = [
          inputs.vyolune.homeManagerModules.default
        ];

        sops.secrets."vyolune/nextcloud-password" = {
          sopsFile = ./secret.yaml;
        };

        services.vyolune = {
          enable = true;
          settings = {
            url = "${nextcloud.endpoint}/remote.php/dav";
            username = "dachxy";
            password_command = /* bash */ "cat ${config.sops.secrets."vyolune/nextcloud-password".path}";

            view = {
              done_linger_secs = 3;
              list_side = "right";
              list_modes = [
                "compact"
                "full"
              ];

              statusline = {
                a = [ "list" ];
                b = [ "mode" ];
                c = [ "hint" ];
                x = [ ];
                y = [
                  {
                    segment = "clock";
                    format = "%H:%M:%S";
                  }
                ];
                z = [ "counts" ];

                options = {
                  separator = "  ";
                  caps = true;
                };
              };
            };
          };

          daemon.enable = true;
        };
      };
    };
}
