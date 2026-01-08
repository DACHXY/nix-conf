{ config, ... }:
{
  sops.secrets."wireguard/wg1.conf" = { };
  networking.wg-quick.interfaces.wg1.configFile = config.sops.secrets."wireguard/wg1.conf".path;
}
