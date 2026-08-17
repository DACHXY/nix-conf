{
  flake.modules.darwin.danny =
    { config, ... }:
    {
      home-manager.users.${config.my.user.name} =
        { config, ... }:
        {
          sops.secrets."vpn/csit" = {
            mode = "0400";
            sopsFile = ./secret.yaml;
          };

          sops.secrets."vpn/csit-test" = {
            mode = "0400";
            sopsFile = ./secret.yaml;
          };

          sops.secrets."vpn/csit-pass" = {
            mode = "0400";
            sopsFile = ./secret.yaml;
          };

          sops.secrets."vpn/nycu" = {
            mode = "0400";
            sopsFile = ./secret.yaml;
          };

          sops.secrets."vpn/nycu-pass" = {
            mode = "0400";
            sopsFile = ./secret.yaml;
          };

          sops.templates."vpn/csit" = {
            content = ''
              ${config.sops.placeholder."vpn/csit"}
              password-file=${config.sops.secrets."vpn/csit-pass".path}
            '';
            path = "${config.home.homeDirectory}/Documents/vpn-configs/csit.conf";
          };

          sops.templates."vpn/csit-test" = {
            content = ''
              ${config.sops.placeholder."vpn/csit-test"}
              password-file=${config.sops.secrets."vpn/csit-pass".path}
            '';
            path = "${config.home.homeDirectory}/Documents/vpn-configs/csit-test.conf";
          };

          sops.templates."vpn/nycu" = {
            content = ''
              ${config.sops.placeholder."vpn/nycu"}
              password-file=${config.sops.secrets."vpn/nycu-pass".path}
            '';
            path = "${config.home.homeDirectory}/Documents/vpn-configs/nycu.conf";
          };

          home.sessionVariables = {
            VPN_SECRETS_DIR = "$HOME/Documents/vpn-configs";
          };
        };
    };
}
