{ hostname }:
{
  pkgs,
  lib,
  config,
  modulesPath,
  ...
}:
let
  inherit (lib) mkForce;
  inherit (builtins) getEnv;

  username = "danny";
  ip = getEnv "CC_IP";
  prefix = 25;
  gateway = getEnv "CC_GATEWAY";
in
{
  # sops.secrets."users/danny/password" = {
  #   neededForUsers = true;
  # };

  systemConf = {
    inherit hostname username;
  };

  virtualisation.vmware.guest.enable = true;

  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ./boot.nix
    ./disk.nix
    ../public/dn/presets/server.nix
    ../../modules/environment.nix
    ../../modules/internationalisation.nix
    ../../modules/misc.nix
    ../../modules/nixsettings.nix
    ../../modules/programs.nix
    ../../modules/services.nix
    ../../modules/users.nix
    ../../modules/sops-nix.nix
    ../../modules/gc.nix
    ../../modules/security.nix
    ../../modules/systemd-resolv.nix
    ../../modules/stylix.nix
    (import ./network.nix { inherit ip prefix gateway; })
  ];

  home-manager.users.${username} =
    { ... }:
    {
      imports = [
        ../../../home/user/nvf.nix
        ../../../home/user/yazi.nix
        ../../../home/user/zellij.nix
        ../../../home/user/environment.nix
        ../../../home/user/ghostty.nix
        ../../../home/user/direnv.nix
        (import ../../../home/user/git.nix {
          username = "dachxy";
          email = "danny01161013@gmail.com";
        })
        ../../../home/user/git.nix
      ];

      programs.btop = {
        enable = true;
        settings = {
          theme_background = false;
          update_ms = 1000;
        };
      };
    };

  # Disable man cache
  documentation.man.cache.enable = mkForce false;

  # ==== Packages ==== #
  environment.systemPackages = with pkgs; [
    openssl
    neovim
    curl
    gitMinimal
  ];

  users.users = {
    root.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJSAOufpee7f8D8ONIIGU3qsN+8+DGO7BfZnEOTYqtQ5 danny@pre7780.dn"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJFQA42R3fZmjb9QnUgzzOTIXQBC+D2ravE/ZLvdjoOQ danny@lap.dn"
    ];

    "${username}" = {
      # hashedPasswordFile = config.sops.secrets."users/danny/password".path;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJSAOufpee7f8D8ONIIGU3qsN+8+DGO7BfZnEOTYqtQ5 danny@pre7780.dn"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJFQA42R3fZmjb9QnUgzzOTIXQBC+D2ravE/ZLvdjoOQ danny@lap.dn"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILSHkPa6vmr5WBPXAazY16+Ph1Mqv9E24uLIf32oC2oH danny@phone.dn"
      ];
    };
  };
}
