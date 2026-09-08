{ inputs, ... }:
{
  flake.modules.nixos.gui = {
    imports = [ inputs.tether.nixosModules.default ];

    programs.tether = {
      enable = true;

      wifi = {
        enable = true;
        openFirewall = true;
      };

      bluetooth = {
        enable = true;
        adapters = [ "hci0" ];
      };

      extensions = [
        "firefox"
        "chromium"
        "thunderbird"
      ];
    };
  };
}
