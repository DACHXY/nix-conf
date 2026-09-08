{
  configurations.nixos.dn-server.module = {
    services.journald.settings.Journal = {
      SystemMaxUse = "10G";
      SystemKeepFree = "100M";
      MaxFileSec = "1month";
    };
  };
}
