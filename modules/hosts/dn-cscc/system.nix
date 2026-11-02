{
  configurations.nixos.dn-cscc.system = "x86_64-linux";

  configurations.nixos.dn-cscc.module = {
    # The CSIT (PEAP) wifi profile keeps autoconnecting and never associates,
    # so NetworkManager never reaches "startup complete" and nm-online -s times
    # out: the unit fails on every switch. Nothing here waits for
    # network-online.target (wired eno1 carries traffic).
    systemd.services.NetworkManager-wait-online.enable = false;
  };
}
