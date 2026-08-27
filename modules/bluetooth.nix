{
  flake.modules.nixos.base = {
    services.blueman.enable = true;

    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings.General = {
        Experimental = true;
        Privacy = "device";
        JustWorksRepairing = "always";
        Class = "0x000100";
        FastConnectable = true;
      };
    };

    boot = {
      extraModprobeConfig = ''
        options bluetooth disable_ertm=Y
      '';
    };
  };
}
