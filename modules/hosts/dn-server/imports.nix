{ config, ... }:
{
  configurations.nixos.dn-server.module =
    { lib, pkgs, ... }:
    {
      imports = with config.flake.modules; [
        nixos.server
        nixos.danny
        nixos.danny-acme
        nixos.nvf
        nixos.punktfunk-server
        generic.dnywe
      ];

      boot.kernelParams = [ "split_lock_detect=off" ];

      # This box serves steam over punktfunk, so the whole graphics/nvidia
      # stack has to stay -- but danny's *desktop* home-manager profile does
      # not: it drags in a rust/clang/go/odin toolchain, cursor and icon
      # themes, pandoc and devenv, ~8 GiB in total. Only the HM half goes:
      # nixos.danny stays, so the extra CA certs (pki), the sops' u2f_keys for
      # FIDO sudo and the sudo-rs rules are all still there.
      home-manager.users = lib.mkForce { };

      # No home-manager here, so the login shell is spelled out instead of
      # coming from the HM profile.
      programs.fish.enable = true;
      users.users.danny.shell = pkgs.fish;
    };
}
