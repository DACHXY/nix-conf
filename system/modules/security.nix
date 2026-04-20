{ config, ... }:
{
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  security.sudo-rs = {
    enable = true;
    execWheelOnly = true;
    extraConfig = ''
      Defaults timestamp_timeout=1
    '';
  };

  security.sudo.enable = !config.security.sudo-rs.enable;
}
