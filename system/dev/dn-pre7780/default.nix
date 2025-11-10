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
    domain = "net.dn";
    enableHomeManager = true;
    nvidia.enable = true;
    hyprland = {
      enable = true;
      monitors = [
        {
          desc = "ASUSTek COMPUTER INC ASUS VG32VQ1B 0x00002271";
          output = "DP-5";
          props = "2560x1440@165, 0x0, 1";
        }
        {
          desc = "Acer Technologies XV272U V3 1322131231233";
          output = "DP-6";
          props = "2560x1440@180, -1440x-600, 1, transform, 1";
        }
      ];
    };
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
      to = 31010;
    }
  ];

  imports = [
    ../../modules/presets/basic.nix
    ./common
    ./games
    ./home
    ./services
    ./sops
    ./utility
    ./virtualisation
  ];

  # Live Sync D
  services.postgresql = {
    ensureUsers = [ { name = "${username}"; } ];
    ensureDatabases = [ "livesyncd" ];
  };

  users.users.${username}.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJFQA42R3fZmjb9QnUgzzOTIXQBC+D2ravE/ZLvdjoOQ danny@lap.dn"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILSHkPa6vmr5WBPXAazY16+Ph1Mqv9E24uLIf32oC2oH danny@phone.dn"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMj/LeB3i/vca3YwGNpAjf922FgiY2svro48fUSQAjOv Shortcuts on :D"
  ];
}
