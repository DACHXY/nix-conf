{
  config,
  ...
}:
{
  networking = {
    firewall = {
      allowedUDPPorts = [ 51820 ];
    };
    wg-quick.interfaces.wg0.configFile = config.sops.secrets."wireguard/conf".path;
  };
}
