{ inputs, config, ... }:
let

  inherit (config.flake.public.config.services) nextcloud;
in
{

  flake.modules.nixos.danny-gui =
    { config, ... }:
    let
      osConfig = config;
    in
    {
      # Decrypted by the system sops-nix (root-only host key), owned by the user.
      sops.secrets."vyolune/nextcloud-password" = {
        sopsFile = ./secret.yaml;
        owner = config.my.user.name;
        mode = "0400";
      };

      home-manager.users.${config.my.user.name} = { config, ... }: {
        imports = [
          inputs.vyolune.homeManagerModules.default
        ];

        services.vyolune = {
          enable = true;
          settings = {
            url = "${nextcloud.endpoint}/remote.php/dav";
            username = "dachxy";
            password_command = /* bash */ "cat ${osConfig.sops.secrets."vyolune/nextcloud-password".path}";

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
