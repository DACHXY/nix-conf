{ config, ... }:
{
  configurations.nixos.dn-workstation.module =
    { ... }@nixosArgs:
    {
      imports = with config.flake.modules; [
        nixos.pc
        nixos.vpn
        nixos.danny
        nixos.danny-acme
        nixos.nvf
        nixos.secure-boot
        nixos.gaming
        nixos.virtualisation
        # nixos.proxy-server
        generic.dnywe
      ];

      home-manager.users.${nixosArgs.config.my.user.name}.imports =
        with config.flake.modules.homeManager; [
          minecraft
        ];
    };
}
