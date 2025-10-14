{ lib, config, ... }:
let
  inherit (lib) mkForce;
in
{
  imports = [
    (import ../../../modules/nvidia.nix {
      nvidia-mode = "offload";
      intel-bus-id = "PCI:0:2:0";
      nvidia-bus-id = "PCI:1:0:0";
    })
  ];

  hardware.nvidia.package = mkForce config.boot.kernelPackages.nvidiaPackages.latest;
  hardware.nvidia.open = mkForce true;
}
