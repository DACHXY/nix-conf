{ config, lib, ... }:
{
  sops = {
    secrets = {
      "wireguard/wg0.conf" = { };
    };
  };
}
