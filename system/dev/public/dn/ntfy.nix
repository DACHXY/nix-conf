{
  self,
  config,
  pkgs,
  lib,
  ...
}:
let
  serverCfg = self.nixosConfigurations.dn-server.config;
  inherit (config.systemConf) username;
  ntfyWrapper = import ../../../../home/scripts/ntfy.nix { inherit config pkgs lib; };
in
{
  sops.secrets."ntfy" = {
    owner = username;
    sopsFile = ../../public/sops/dn-secret.yaml;
    mode = "0600";
  };

  home-manager.users."${username}" = {
    home.packages = [
      ntfyWrapper
    ];

    services.ntfy-client =
      let
        icon = builtins.fetchurl {
          url = "https://docs.ntfy.sh/static/img/ntfy.png";
          sha256 = "sha256:0igypv27phrhgiccvnrcvi543yz8k8rvsxkn4nha2l3xx92yx6r5";
        };
      in
      {
        enable = true;
        settings = {
          default-host = serverCfg.services.ntfy-sh.settings.base-url;
          subscribe = [
            {
              topic = "public-notifications";
              command = ''
                notify-send -i ${icon} "[$topic] $title" "$message"
              '';
            }
          ];
        };
        environmentFile = config.sops.secrets."ntfy".path;
      };
  };
}
