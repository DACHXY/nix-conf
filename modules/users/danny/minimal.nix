{ config, ... }:
let
  flakeModuleDannyKeys = config.flake.modules.generic.danny-keys;
in
{
  # Headless hosts (dn-gcp) get a login, an SSH key set and fish — nothing
  # else. `generic.danny` drags in the whole home-manager desktop profile
  # (niri, noctalia, mesa, webkitgtk, browsers), which is ~3 GiB of store
  # on a box that never opens a window.
  flake.modules.nixos.danny-minimal = {
    imports = [
      config.flake.modules.generic.danny-minimal
      config.flake.modules.nixos.server-rules
    ];
  };

  flake.modules.generic.danny-minimal =
    { config, pkgs, ... }:
    {
      imports = [ flakeModuleDannyKeys ];

      my.user = {
        name = "danny";
        email = "dachxy@dnywe.com";
      };

      programs.fish.enable = true;

      users.users.${config.my.user.name} = {
        shell = pkgs.fish;
      };
    };
}
