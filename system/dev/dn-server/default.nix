{
  pkgs,
  inputs,
  username,
  ...
}:
{
  imports = [
    (import ../../modules/nvidia.nix {
      nvidia-mode = "offload";
      intel-bus-id = "PCI:0:2:0";
      nvidia-bus-id = "PCI:1:0:0";
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
    users."${username}" = {
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

        # Git
        (import ../../../home/user/git.nix {
          inherit username;
          email = "danny10132024@gmail.com";
        })
      ];
    };
  };
}
