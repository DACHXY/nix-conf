{ config, ... }:
let
  inherit (config.flake.public.config) domain;
in
{
  configurations.nixos.dn-server.module =
    { lib, config, ... }:
    let
      inherit (lib)
        attrNames
        attrValues
        concatMap
        filter
        hasPrefix
        hasSuffix
        unique
        ;

      vhosts = config.services.nginx.virtualHosts;

      # Every name served by this host's own nginx (primary name + aliases)
      # that belongs to our domain.
      servedNames =
        attrNames vhosts ++ concatMap (v: v.serverAliases or [ ]) (attrValues vhosts);

      # On dn-server the only resolver is 127.0.0.1 (NetworkManager
      # insertNameservers), which depends on the whole DNS stack
      # (dnsdist -> pdns-recursor -> pdns-as-gpgsql) being up. Pointing our own
      # service names at loopback makes local clients independent of that
      # stack: e.g. netbird-wt0 bootstraps against https://netbird.<domain>
      # and keycloak discovery goes through https://login.<domain>, both of
      # which just hit the local nginx. Names served by other hosts (coturn on
      # dn-cc, aria on dn-workstation, mx2, ...) are not in this list, so they
      # keep resolving through the normal chain.
      localHostnames = unique (
        filter (n: !(hasPrefix "*" n) && (n == domain || hasSuffix ".${domain}" n)) servedNames
      );
    in
    {
      networking.hosts."127.0.0.1" = localHostnames;
    };
}
