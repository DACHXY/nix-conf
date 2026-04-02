{ hostname }:
{
  pkgs,
  helper,
  ...
}:
let
  inherit (helper) capitalize;
  username = "danny";
in
{
  systemConf = {
    inherit hostname username;
    enableHomeManager = true;
    windowManager = "niri";
    nvidia.enable = true;
    sddm.package = (
      pkgs.sddm-astronaut.override {
        embeddedTheme = "purple_leaves";
        themeConfig = {
          ScreenWidth = "2560";
          ScreenHeight = "1440";
          Font = "SF Pro Display Bold";
          HeaderText = "Welcome, ${capitalize username}";
        };
      }
    );
  };

  networking.firewall.allowedTCPPortRanges = [
    {
      from = 8000;
      to = 8100;
    }
    {
      from = 31000;
      to = 32000;
    }
  ];

  nix.settings.download-buffer-size = 671088640;

  imports = [
    ../../modules/presets/basic.nix
    ../public/dn/presets/local.nix
    ./sops
    ./network
    ./common
    ./games
    ./home
    ./utility
    ./virtualisation
    ../../modules/shells/noctalia
    ../../modules/sunshine.nix
    # ../../modules/secure-boot.nix
    ../../modules/card-reader.nix
  ];

  users.users.${username} = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJFQA42R3fZmjb9QnUgzzOTIXQBC+D2ravE/ZLvdjoOQ danny@lap.dn"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILSHkPa6vmr5WBPXAazY16+Ph1Mqv9E24uLIf32oC2oH danny@phone.dn"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMj/LeB3i/vca3YwGNpAjf922FgiY2svro48fUSQAjOv Shortcuts on :D"
    ];
  };

  users.users.root = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJFQA42R3fZmjb9QnUgzzOTIXQBC+D2ravE/ZLvdjoOQ danny@lap.dn"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILSHkPa6vmr5WBPXAazY16+Ph1Mqv9E24uLIf32oC2oH danny@phone.dn"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMj/LeB3i/vca3YwGNpAjf922FgiY2svro48fUSQAjOv Shortcuts on :D"
    ];
  };
}
