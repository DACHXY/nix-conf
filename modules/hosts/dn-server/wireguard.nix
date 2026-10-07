{
  configurations.nixos.dn-server.module =
    { config, lib, pkgs, ... }:
    let
      # The NixOS wg-quick module, when `configFile` is used, copies the file to
      # /tmp/<iface>.conf at start inside a PrivateTmp namespace. `preStop` then
      # runs in a fresh namespace where that copy no longer exists, so the stop
      # fails (`/tmp/wgN.conf does not exist`) and the interface is left up; the
      # next start then aborts with "`wgN' already exists". Re-copy the secret
      # before tearing the interface down so stop/restart (incl. nixos-rebuild)
      # works.
      mkPreStop =
        iface: ''
          cp ${config.sops.secrets."wireguard/${iface}.conf".path} /tmp/${iface}.conf
          ${pkgs.wireguard-tools}/bin/wg-quick down /tmp/${iface}.conf
        '';
    in
    {
      sops.secrets."wireguard/wg1.conf" = { };
      sops.secrets."wireguard/wg2.conf" = { };
      networking.wg-quick.interfaces.wg1.configFile = config.sops.secrets."wireguard/wg1.conf".path;
      networking.wg-quick.interfaces.wg2.configFile = config.sops.secrets."wireguard/wg2.conf".path;
      systemd.services."wg-quick-wg1".preStop = lib.mkForce (mkPreStop "wg1");
      systemd.services."wg-quick-wg2".preStop = lib.mkForce (mkPreStop "wg2");
    };
}
