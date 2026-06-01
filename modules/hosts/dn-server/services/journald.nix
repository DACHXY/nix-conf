{
  configurations.nixos.dn-server.module = {
    services.journald.extraConfig = ''
      SystemMaxUse=10G
      SystemKeepFree=100M
      MaxFileSec=1month
    '';
  };
}
