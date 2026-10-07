{ inputs, lib, ... }:
{
  configurations.nixos.generic.module = {
    imports = [
      "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
    ];

    # installation-device.nix sets PermitRootLogin = mkDefault "yes"; the shared base
    # module sets mkDefault "no", which now conflicts. Force "yes" for the installer.
    services.openssh.settings.PermitRootLogin = lib.mkForce "yes";
  };
}
