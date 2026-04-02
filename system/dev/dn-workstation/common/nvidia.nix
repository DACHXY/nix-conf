{ ... }:
{
  imports = [
    (import ../../../modules/nvidia.nix {
      nvidia-mode = "offload";
      intel-bus-id = "PCI:0@0:2:0";
      nvidia-bus-id = "PCI:30@0:0:0";
    })
  ];
}
