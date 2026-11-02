{ inputs, lib, ... }:
{
  flake.modules.nixos.gui = {
    imports = [ inputs.tether.nixosModules.default ];

    # tether still sets the obsolete services.avahi.publish.{enable,userServices}
    # (upstream nix/module.nix). Nulling them restores the same settings by hand
    # and drops the deprecation warnings. Drop this once tether uses
    # services.avahi.settings.publish directly.
    services.avahi.publish.enable = lib.mkForce null;
    services.avahi.publish.userServices = lib.mkForce null;
    services.avahi.settings.publish = {
      disable-publishing = false;
      disable-user-service-publishing = false;
      publish-addresses = true;
    };

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
