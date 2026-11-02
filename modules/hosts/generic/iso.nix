{ inputs, lib, ... }:
{
  configurations.nixos.generic.module = {
    imports = [
      "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
    ];

    # installation-device.nix sets PermitRootLogin = mkDefault "yes"; the shared base
    # module sets mkDefault "no", which now conflicts. Force "yes" for the installer.
    services.openssh.settings.PermitRootLogin = lib.mkForce "yes";

    # The installer image pulls in zfs, and zfs 2.4.4 is marked broken on the
    # latest kernel (7.3) the shared base module pins. Build the image on the
    # stable kernel from the same nixpkgs input instead. (`nixpkgs.config` is not
    # available here: the flake hands NixOS a pre-built `nixpkgs.pkgs`.)
    boot.kernelPackages =
      lib.mkForce inputs.nixpkgs.legacyPackages.x86_64-linux.linuxPackages;
  };
}
