{ config, ... }:
{
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
    settings = {
      sunshine_name = config.networking.hostName;
    };
  };
}
