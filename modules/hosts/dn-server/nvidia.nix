{ config, ... }:
{
  configurations.nixos.dn-server.module = {
    imports = with config.flake.modules.nixos; [
      nvidia-gpu
    ];

    hardware.nvidia.prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };

      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };
}
