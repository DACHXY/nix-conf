{
  pkgs,
  settings,
  config,
  ...
}:
{
  imports = [
    (import ../../modules/nvidia.nix {
      nvidia-mode = settings.nvidia.mode;
      intel-bus-id = settings.nvidia.intel-bus-id;
      nvidia-bus-id = settings.nvidia.nvidia-bus-id;
    })
    ./hardware-configuration.nix
    ./boot.nix
    ./sops-conf.nix
    # ./nginx.nix
    ../../modules/certbot.nix
    ../../modules/presets/basic.nix
    ../../modules/gaming.nix
    ../../modules/secure-boot.nix
    ../../modules/virtualization.nix
    ../../modules/wine.nix
    ../../modules/wireguard.nix
    (import ../../modules/rustdesk-server.nix { relayHosts = [ "10.0.0.0/24" ]; })
    # (import ../../modules/nextcloud.nix {
    #   hostname = "192.168.0.3";
    #   datadir = "/mnt/nextcloud";
    #   https = false;
    # })
    ../../modules/mail-server
  ];

  mail-server = {
    enable = true;
    mailDir = "~/Maildir";
    virtualMailDir = "/var/mail/vhosts";
    domain = "vmail.net.dn";
    networks = [
      "127.0.0.0/8"
      "10.0.0.0/24"
    ];
    openFirewall = true;
    sslKey = "/etc/letsencrypt/live/vmail.net.dn/privkey.pem";
    sslCert = "/etc/letsencrypt/live/vmail.net.dn/fullchain.pem";
    dovecot.ldapFile = config.sops.secrets."dovecot/openldap".path;
    openldap = {
      passwordFile = config.sops.secrets."openldap/adminPassword".path;
      enableWebUI = true;
    };
  };

  home-manager = {
    users."${settings.personal.username}" = {
      imports = [
        ../../../home/presets/basic.nix
        (import ../../../home/user/bitwarden.nix {
          email = "danny@dn-server.net.dn";
          baseUrl = "https://bitwarden.net.dn";
        })
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    prismlauncher
    heroic
  ];

  users.users = {
    "${settings.personal.username}" = {
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJFQA42R3fZmjb9QnUgzzOTIXQBC+D2ravE/ZLvdjoOQ danny@lap.dn"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILSHkPa6vmr5WBPXAazY16+Ph1Mqv9E24uLIf32oC2oH danny@phone.dn"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMj/LeB3i/vca3YwGNpAjf922FgiY2svro48fUSQAjOv Shortcuts on :D"
      ];
    };
  };

}
