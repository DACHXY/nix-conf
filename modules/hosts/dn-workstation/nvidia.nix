{ config, ... }:
{
  configurations.nixos.dn-workstation.module = {
    imports = with config.flake.modules.nixos; [
      nvidia-gpu
    ];

    hardware.nvidia.prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };

      intelBusId = "PCI:0@0:2:0";
      nvidiaBusId = "PCI:30@0:0:0";
    };
  };
}
