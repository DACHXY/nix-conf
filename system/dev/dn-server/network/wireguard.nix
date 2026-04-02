{ config, ... }:
{
  sops.secrets."wireguard/wg1.conf" = { };
  sops.secrets."wireguard/wg2.conf" = { };
  networking.wg-quick.interfaces.wg1.configFile = config.sops.secrets."wireguard/wg1.conf".path;
  networking.wg-quick.interfaces.wg2.configFile = config.sops.secrets."wireguard/wg2.conf".path;
}
