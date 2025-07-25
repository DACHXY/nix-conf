{
  relayHosts ? [ ],
}:
{
  lib,
  ...
}:
{
  services.rustdesk-server = {
    enable = true;
    openFirewall = true;
    relay.enable = true;
    signal.relayHosts = relayHosts;
  };
}
