{ config, lib, ... }:
{
  sops = {
    secrets = {
      "wireguard/conf" = { };
    };
  };
}
