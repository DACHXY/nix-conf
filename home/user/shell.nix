{ ... }:
{
  programs = {
    nushell = {
      enable = true;
      configFile.source = ../config/nushell/config.nu;
      envFile.source = ../config/nushell/env.nu;
    };

    carapace.enable = true;
    carapace.enableNushellIntegration = true;

    starship = {
      enable = true;
    };

    zoxide = {
      enable = true;
      enableNushellIntegration = true;
    };
  };
}
