{
  imports = [
    (import ../../../modules/fail2ban.nix {
      extraAllowList = [
        "10.0.0.0/24"
        "122.117.215.55"
        # Netbird
        "100.104.0.0/16"
      ];
    })
  ];
}
