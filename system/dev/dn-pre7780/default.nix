{
  pkgs,
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
    ./hardware-configuration.nix
    ./boot.nix
    ./sops-conf.nix
    ./nginx.nix
    ../../modules/presets/basic.nix
    ../../modules/gaming.nix
    ../../modules/secure-boot.nix
    ../../modules/virtualization.nix
    ../../modules/wine.nix
    ../../modules/wireguard.nix
    (import ../../modules/nextcloud.nix {
      hostname = "pre-nextcloud.net.dn";
      datadir = "/mnt/nextcloud";
    })
  ];

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

  # Disable integrated bluetooth adapter
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTRS{idVendor}=="8087", ATTRS{idProduct}=="0033", ATTR{authorized}="0"
  '';

  environment.systemPackages = with pkgs; [
    prismlauncher
  ];

  users.users = {
    "${settings.personal.username}".openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJFQA42R3fZmjb9QnUgzzOTIXQBC+D2ravE/ZLvdjoOQ danny@lap.dn"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILSHkPa6vmr5WBPXAazY16+Ph1Mqv9E24uLIf32oC2oH danny@phone.dn"
    ];
  };
}
