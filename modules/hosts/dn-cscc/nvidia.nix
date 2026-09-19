{ config, ... }: {
  configurations.nixos.dn-cscc.module =
    { ... }@nixosArgs:
    {
      imports = with config.flake.modules.nixos; [
        nvidia-gpu
        virtual-display
      ];

      hardware.nvidia = {
        powerManagement.enable = false;
        open = false;
        dynamicBoost.enable = false;
        package = nixosArgs.config.boot.kernelPackages.nvidiaPackages.legacy_580;
      };
    };
}
