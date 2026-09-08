{ config, ... }:
{
  configurations.darwin.dn-notebook.module = {
    imports = with config.flake.modules; [
      darwin.laptop
      darwin.danny
      darwin.vpn
      darwin.nvf
      generic.dnywe

      # ==== AI ==== #
      generic.ai
      generic.danny-ai
    ];
  };
}
