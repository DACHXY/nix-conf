{
  relayHosts ? [ ],
}:
{
  lib,
  ...
}:
{
  services.rustdesk-server = {
    enable = lib.mkDefault true;
    openFirewall = lib.mkDefault true;
    relay.enable = lib.mkDefault false;
    signal.relayHosts = relayHosts;
  };
}
