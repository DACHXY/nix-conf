{
  pkgs,
  inputs,
  settings,
  ...
}:
{
  imports = [
    (import ../../modules/nvidia.nix {
      nvidia-mode = settings.nvidia.mode;
      intel-bus-id = settings.nvidia.intel-bus-id;
      nvidia-bus-id = settings.nvidia.nvidia-bus-id;
    })
    ./sops-conf.nix
    ./boot.nix
    ./hardware-configuration.nix
    ./networking.nix
    ./services.nix
    ./nginx.nix
    ./step-ca.nix
    ./mail-server.nix
    ../../modules/presets/minimal.nix
    ../../modules/bluetooth.nix
    ../../modules/gc.nix
    ../../modules/certbot.nix
    (import ../../modules/nextcloud.nix {
      hostname = "nextcloud.net.dn";
      dataBackupPath = "/mnt/backup_dn";
      dbBackupPath = "/mnt/backup_dn";
    })
    (import ../../modules/vaultwarden.nix {
      domain = "https://bitwarden.net.dn";
    })
    (import ../../modules/openldap.nix { })
    ../../modules/terraria.nix
  ];

  environment.systemPackages = with pkgs; [
    ferium
    openssl
  ];

  home-manager = {
    users."${settings.personal.username}" = {
      imports = [
        ../../../home/user/config.nix
        ../../../home/user/direnv.nix
        ../../../home/user/environment.nix
        ../../../home/user/git.nix
        ../../../home/user/nvim.nix
        ../../../home/user/shell.nix
        ../../../home/user/tmux.nix
        ../../../home/user/yazi.nix
        {
          home.packages = with pkgs; [
            inputs.ghostty.packages.${system}.default
            (python3.withPackages (
              p: with p; [
                pip
              ]
            ))
          ];
        }
      ];
    };
  };
}
